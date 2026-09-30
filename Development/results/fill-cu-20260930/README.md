# C512 / ViT 填满度（fill-cu，2026-09-30 晚）

**结论先行**：C512 与 ViT 各核按 VGPR/LDS 算都能一轮全部驻留（每 SIMD 约 3～9 wave，驻留上限 7～16），**没有"最后一波只占几个 CU"的尾巴**；只有 split_ffn（900 23.5 wave/SIMD vs 上限 13）、ViT qkv_w5（18.8 vs 10）和 1080 ViT expand 超上限，按轮次模型尾部空转上界每档约 0.03～0.05ms（单 WG 短、动态调度，实际更小）。**延迟型**核（单 WG 就占全量 45～92%）是 mix、C512 attn-project、ViT contract、pool_project_c512、ViT project——病根不是填满度，是单 wave 的串行链。收 1 刀：**C512 attn-project 残差初始化外提（`HIP_C512_HOIST_RES 1`，现成宏，从没量过）**，逐位，两档三轮全正：900 −0.022～−0.031ms、1080 −0.026～−0.035ms，p99 合并 8.102→8.053 / 10.923→10.892。已装剑星、鬼武者。

## 1. 填满度账（jobbench，截 grid.x 扫描，`sweep.csv`；低 grid 有时钟爬升噪声）

驻留上限按 1536 VGPR/SIMD（wave32）与 64KB LDS/CU 估；"单 WG" = grid.x 取 1～2 的最小值。

|id|核|次/帧|WG×线程|wave 数|wave/SIMD|VGPR/LDS|驻留上限 wave/SIMD|单 WG µs|全量 µs|单/全|
|---|---|---:|---|---:|---:|---|---:|---:|---:|---:|
|o900-023|split_mix_blocked_h16w_m32|13|376×32|376|2.9|102/4096|8|10.1|15.6|65%|
|o900-024|split_ffn_fused_fp8_t8|13|752×128|3008|23.5|108/5184|13|2.5|13.6|19%|
|o900-025|split_projection_frag|13|752×32|752|5.9|83/1024|16|3.7|17.7|21%|
|o900-026|c512_qkv_attention_compact|6|448×64|896|7.0|134/6144|10|11.8|37.7|31%|
|o900-031|c512_qkv_attention_compact|7|560×64|1120|8.8|134/6144|10|10.8|49.6|22%|
|o900-027|mh_attention_project_frag_c512|13|752×32|752|5.9|80/0|16|12.3|18.0|68%|
|o900-063|mh_pool_project_group_c512|1|25×512|400|3.1|98/16640|14|18.9|20.5|92%|
|o900-064|vit_gather|2|1600×256|12800|100.0|6/0|16|1.9|10.0|19%|
|o900-065|vit_pack_input|8|400×256|3200|25.0|7/0|16|1.9|2.4|79%|
|o900-066|vit_expand_blocked_fp8_frag_bytein|8|1600×32|1600|12.5|77/0|16|4.5|22.9|20%|
|o900-067|vit_stream_contract_frag_hout|8|400×32|400|3.1|205/4096|7|17.4|26.9|65%|
|o900-068|vit_stream_qkv_frag_hin_w5|8|480×160|2400|18.8|113/16384|10|5.8|29.6|20%|
|o900-069|vit_attention_fused_400_bytein_bout|8|800×32|800|6.2|68/0|16|6.0|15.1|40%|
|o900-070|vit_stream_project_n64_bh|8|400×32|400|3.1|120/0|12|5.1|9.1|56%|
|o1080-021|split_mix_blocked_h16w_m32|13|544×32|544|4.2|102/4096|8|10.1|19.7|51%|
|o1080-022|split_ffn_fused_fp8_t8|13|1080×128|4320|33.8|108/5184|13|2.5|18.9|13%|
|o1080-023|split_projection_frag|13|1080×32|1080|8.4|83/1024|16|3.7|15.0|25%|
|o1080-024|c512_qkv_attention_compact|13|640×64|1280|10.0|134/6144|10|11.7|53.8|22%|
|o1080-025|mh_attention_project_frag_c512|13|1080×32|1080|8.4|80/0|16|12.1|25.3|48%|
|o1080-061|mh_pool_project_group_c512|1|40×512|640|5.0|98/16640|14|18.8|26.8|70%|
|o1080-064|vit_expand_blocked_fp8_frag_bytein|8|2560×32|2560|20.0|77/0|16|4.6|35.3|13%|
|o1080-065|vit_stream_contract_frag_hout|8|640×32|640|5.0|205/4096|7|16.9|37.7|45%|
|o1080-066|vit_stream_qkv_frag_hin_w5|8|768×160|3840|30.0|113/16384|10|5.8|44.2|13%|
|o1080-073|vit_attention_fused_640_bytein_bout|8|1280×32|1280|10.0|68/0|16|9.3|49.3|19%|
|o1080-068|vit_stream_project_n64_bh|8|640×32|640|5.0|120/0|12|5.1|11.6|43%|

读法：单/全 ≤ 25% 的是吞吐型（CU 已满，差距在指令条数）：split_ffn/projection、c512_qkv_attention、ViT expand/qkv_w5/attention。单/全 ≥ 45% 的是延迟型。

## 2. 候选与结果（核级：同 job 同 fixture，输出缓冲 FNV 哈希 + 128 次图捕获 7 轮中位，ABAB 三轮，`kab.ps1`）

| 候选 | 做法 | 核级逐位 | 核级时长 | 结论 |
|---|---|---|---|---|
| N-split（`C512_SPLIT_N`） | mix / attn-project 每 wave 只算 32 列（WG64 同 grid 或 WG32 grid×2），K 顺序不动 | SAME | 慢 1～3µs | 不收。每 wave 的 A 读取条数不变，链不变短 |
| mix K 循环软件流水（`C512_MIX_PIPE 1/2`） | 编译器只预取了 a0，a1/B 每拍串行等两次；显式提前一拍发射 | SAME | 1：+2.9µs；2：±1 噪声 | 不收。全量时 mix 受访存限，单 wave 链被别的 wave 掩住 |
| **attn-project 残差外提（`HIP_C512_HOIST_RES 1`）** | 条件里 33 对"读-等 0"串行 → 4 个 scale + 32 个 feature 先全读（越界行夹到 first），再 select | SAME | 900 17.0→13.3～14.9µs；1080 −0.2/−3.1/−1.9 | **收** |
| decoder_project2x skip 预读（`HIP_DEC_HOIST_SCALE 2`） | 尾部 32 个 skip 每个都排在前一个 out 写之后（177 处串行）；先全读 | SAME | −1.5/+2/+1.2/−2.5µs | 不收（不全正） |

ISA 串行段扫描（`serial.py` 的全模块版：`s_wait_loadcnt 0x0` 前在飞 ≤2 条读）：ViT 各核 ≤5，无同病；其余多的在 C64/C128 wave2（18～50）、C32（9～33），不在本轮范围，留作线索。

## 3. 整网（HR，只换 multihead-fast-padded-wave-packed，宿主不变）

- 逐位：7 用例 × EXACT/AE × 12 帧 = 168 帧 + AE 决策 CSV + 900/1080 history 强制票号回绕，19 组全 SAME。
- ABBA（1000 帧弃 200）：

| 轮 | 900 avg | 1080 avg |
|---|---|---|
| 1 | 7.6615→7.6346（−0.027） | 10.4854→10.4595（−0.026） |
| 2 | 7.6839→7.6533（−0.031） | 10.5070→10.4723（−0.035） |
| 3 | 7.6891→7.6667（−0.022） | 10.5197→10.4889（−0.031） |
| 合并 p99 | 8.102→8.053 | 10.923→10.892 |

- 配方：`hip/build-modules.ps1` 的 multihead-fast-padded-wave-packed 行加 `HIP_C512_HOIST_RES 1`；配方重编 gfx1201 `.text` 与实测候选相同。模块 gfx1200 BBBFACE9…、gfx1201 47F00EBA…。
- 装机：剑星只换该模块两架构（add-on 6d059845、flags 不动，62 模块 SHA256SUMS 重建），备份 `D:\DLSSNR-Lab\hip-backend\fill-cu-20260930\backups\stellar-20260930-220046-fill`；鬼武者镜像模块（runtime 5e601d57 不变），备份 `D:\DLSSNR-Lab\onimusha-backups\20260930-220046-fill`。RE9 runtime 未变，不重编。帧转储已删（5.3GB）。

## 文件

`filltab.md`、`sweep.csv`。脚本 `Development/HIP/experiments/fill-cu/`（jobbench-grid.cpp：`JB_GRIDX/JB_GRIDMUL/JB_BLOCKX/JB_SYMBOL/JB_MODULE` 覆盖＋输出哈希；sweep/kab/build/setup/run/full/summarize/p99m/final/install.ps1；filltab.py、serial.py 需把现装模块拷到 `mods/`）。lab `D:\DLSSNR-Lab\hip-backend\fill-cu-20260930`。

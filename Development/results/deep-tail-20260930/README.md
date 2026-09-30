# multihead/deep 字节出口 LDS 转置宽写（2026-09-30）：收 C512 t8 两核，ViT QKV 不收；逐位，已装

**结论**：网络里仍是"每 lane 持一列、逐字节写"的旧出口按热度排了一遍，做了前两个：
- **S（收）** `C512_T8_TAIL_VEC 1`（deep_fast-packed）：`split_ffn_fused_fp8_t8`、`split_projection_frag` 的 E4M3 分块副本（16 token × 64 通道 = 两块连续 512 字节）先在 LDS 按同一布局摆好，再每 lane 连续宽写（ffn 128 线程各 b64；projection 32 线程各 2×b128）。逐位 19 组 SAME；三轮两档 avg 全正，**900 −0.008～−0.009ms、1080 −0.005～−0.028ms**，三轮合并 p99 两档都变好。已装剑星、鬼武者。
- **V（不收）** `VIT_QKV_TAIL_VEC`（vit-stream，源码默认 0，配方不开）：`vit_stream_qkv_frag_hin_w5` 字节尾经本 wave 已空闲的 norm tile 转置，16 次 store_b8 → 1 次 b128。逐位 19 组 SAME，但三轮符号不一（900 −0.013/+0.007/−0.006、1080 +0.014/−0.007/+0.008，合并 1080 avg +0.005），按新规不收。

## 1. 出口清单（900 地图 `kernel-map-900-20260930`；gfx1201 现装 ISA 数 global_store_b8）

| 核（模块） | 次/帧 | 总 µs | 字节出口形态 | 本轮 |
|---|---|---|---|---|
| vit_stream_qkv_frag_hin_w5（vit-stream） | 8 | 213 | 16×b8/lane，行主序 1024 步长，每 wave 16 行×32 字节 | V：做了，null |
| split_ffn_fused_fp8_t8（deep_fast-packed） | 13 | 188 | 8×b8/lane（分块副本），另有 f32 主输出 8×b32 | S：收 |
| vit_expand_blocked_fp8_frag_bytein | 8 | 174 | 63×b8（hidden 字节，列布局） | 未做（剩余最热） |
| mh_ffn_fused_c256_…_qkv(_bytein)_fb_pdl（multihead-fast-padded-wave） | 4 | 196 | 9×b8，未细查 | 未做 |
| split_projection_frag（deep_fast-packed） | 13 | 127 | 32×b8/lane（分块副本） | S：收 |
| vit_attention_fused_400_bytein_bout | 8 | 117 | 生产走 deep_fast-packed（TRANSPOSED_AV），已是每 lane 8 连续字节 2×b64；c512-m32-deep 里无该宏的同名副本才是 16×b8，不被调用 | 已宽 |
| decoder_project2x_h16w_byteout | 1 | 35 | 48×b8，上采样 2×2 散写 | 冷，不做 |
| vit_stream_contract_frag_hout | 8 | 197 | 32×b16（half 输出） | 非字节，未动 |

LDS 余量：S 两核原来 ffn 4160B / projection 0B，各加 1KB，占用不受 LDS 限制（ffn 128 线程组、projection 单 wave）；V 复用已有 16KB 中本 wave 的 2112B，不加 LDS。

## 2. 做法与逐位依据

每元素的值和 `cvt_pk_fp8` 调用与原式完全相同，只是字节先写 LDS（与 global 同一 16×32 行主序块布局），`WG_FENCE(3)` + barrier（ffn 为 s_barrier，单 wave 核为 wave_barrier）+ `WG_FENCE(2)` 后按连续字节读回、宽写。out8 块地址：ffn `(first+g*2)*512`，projection `(first+row/32)*512`，均为两块 512 字节相邻。f32 主输出不变。

**静态指令（gfx1201，整核）**：
- split_projection_frag：VALU 565→513、访存 123→93、等待 112→96；global_store_b8 32 → ds_store_b8 32 + 2 ds_load_b128 + 2 global_store_b128。
- split_ffn_fused_fp8_t8：VALU 637→649、访存 58→51、等待 90→94；8 b8 → 8 ds_store_b8 + ds_load_b64 + global_store_b64。
- vit_stream_qkv_frag_hin_w5：VALU 307→306、访存 38→23、LDS 36→53、等待 87→92。

## 3. 验证与计时

- 配方旧默认编出与现装 vit-stream / deep_fast-packed `.text/.rodata/.note` 逐字节同；配方直编 final 与实测 S 两架构同。
- 7 用例 × EXACT/AE × 12 帧、AE CSV、900/1080 票号回绕：V、S 各 **19 组 SAME**。
- ABBA（1000 帧弃 200，base = benchmark-P + 现装 31 模块，宿主不变）：

| 候选 | 轮 | 900 avg（p99） | 1080 avg（p99） |
|---|---|---|---|
| S | 1 | 7.6796→7.6702，−0.009（7.914→7.889） | 10.5232→10.5185，−0.005（10.812→10.822） |
| S | 2 | 7.6993→7.6917，−0.008（7.941→7.912） | 10.5235→10.5179，−0.006（10.823→10.854） |
| S | 3 | 7.6928→7.6852，−0.008（7.929→7.930） | 10.5308→10.5032，−0.028（10.853→10.760） |
| S | 合并 | 7.6906→7.6824（p99 7.935→7.912） | 10.5258→10.5132（p99 10.826→10.812） |
| V | 1/2/3 | −0.013 / +0.007 / −0.006 | +0.014 / −0.007 / +0.008 |
| V | 合并 | 7.6915→7.6873（p99 7.931→7.928） | 10.5236→10.5286（p99 10.836→10.817） |

只收一个候选，无需合并再确认。

## 4. 装机

- deep_fast-packed：gfx1201 **7FFAA65F**（`7FFAA65FB0C9839F8F1F734DA1ED3F90C7479F667E74DEEAC111874A6FEF6943`）/ gfx1200 **EBC7DF69**（`EBC7DF6945BEEBD28A349BBFD0BD01086385BAB47750C1EA2122EAB912E63400`）。
- 剑星：只换两架构 deep_fast-packed、重建 SHA256SUMS（62），add-on 6d059845 不变，三个 flags 核过未动。备份 `D:\DLSSNR-Lab\hip-backend\deep-tail-20260930\backups\stellar-20260930-130927-deeptail`。
- 鬼武者：模块与剑星对齐，runtime（含 `_storage_`）5e601d57 未换，备份 `D:\DLSSNR-Lab\onimusha-backups\20260930-130927-deeptail`。
- RE9 runtime 5e601d57 不变（导出名不变），未重编。没发包。回滚 `install.ps1 -RestoreStellar/-RestoreOni <备份>`。
- 9070 D 盘满（0GB）导致第一次跑挂：删了已交账的 c32-align、small-wins 两个 lab 里的 correct/adaptive 帧转储（约 46GB），计时与结论不受影响。

复现：`Development/HIP/experiments/deep-tail/`（setup → build → run.ps1 -Name S -Module deep_fast-packed -Defs 'C512_T8_TAIL_VEC 1' → p99m → final → install）。lab `D:\DLSSNR-Lab\hip-backend\deep-tail-20260930`。

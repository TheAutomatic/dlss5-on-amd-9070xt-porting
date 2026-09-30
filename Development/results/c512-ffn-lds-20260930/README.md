# C512 FFN 按 W5 组织：同组 wave 经 LDS 共用权重分块——逐位，900 单核变慢，停（2026-09-30）

**结论：单核不赢（900 慢 1～5%，1080 快 1～6% 且批间漂），按任务单停在原型，不写宿主、不整网、不装机、不发包。** 源码留宏 `C512_MIX_LDS_G`（默认 0；默认编出的 c512-m32-deep gfx1201 .text 与剑星现装 8e84f7c0 逐字节同）。

## 1. Daniel 这条链怎么组织（0.5.0/0.5.1 同核，`_Z14k_reg_vit_ffwdILi1ELb0ELb0EEv13VitFfwdParams`，900 每块 1 派发 ~29µs）

- **组大小 1 wave**（max_flat_workgroup_size 32），grid (104,8)：x = 16 token 一片（52×32=1664 token），y = 8 列块。900 共 832 个单 wave 组。
- **LDS 0、barrier 0**，没有任何组内共享；80 VGPR、无 spill。
- 一个核做完整 FFN（我们三核：mix → split_ffn → split_projection），hidden 全程在寄存器里（`v_cvt_pk_fp8_f32` 36 条就地转 FP8 喂下一段 WMMA）。
- 数学：激活和权重都 FP8，`v_wmma_f32_16x16x16_fp8_fp8` 20 条/每段循环体、`global_load_b64` 20 条（一条 b64 = 8 个 FP8 = 一个 B 片段），fma_mix/pk_max/pk_min 做 half 累加与 GELU 夹取。
- 对照我方：mix(m32) 每 wave 32 token×64 列、A 是 f32（每 K16 两条 b128）、B 是 f16（每 K16 四条 b128）；每 8 条 WMMA 8 条 b128。Daniel 每条 WMMA 一条 b64。**他快在数据形态（FP8 字节减半/四分之一）和三核合一，不在 LDS 共享**——这是本轮最重要的对照结论。

## 2. 原型（只做最重的 split_mix_blocked_h16w_m32，900 13 次 209µs）

`hip/c512_m32_deep.inc` 新增导出 `split_mix_blocked_h16w_m32_lds`：G 个 wave（G=4 或 2）同组、同一 64 列行块，**每 wave 仍是原来的 32 token 工作量**（wave 总数不变）；half 权重按 64 列×64 K = 8KB 一块，组内协作搬进 LDS，双缓冲、每块 1 次 barrier（照 W5）。A 读取、WMMA 操作数方向、K 顺序、F(Hrtz()) 收尾逐字照旧。grid = 8·ceil(ceil(tokens/32)/G)。

| 变体 | G | kk 展开 | VGPR | LDS | scratch |
|---|---:|---:|---:|---:|---:|
| 现役 m32 | 1 | — | 102 | 4096（占用上限垫片） | 0 |
| u4 | 4 | 4 | 198 | 16KB | 0 |
| u2 | 4 | 2 | 141 | 16KB | 0 |
| u1 | 4 | 1 | 121 | 16KB | 0 |
| g2u2 | 2 | 2 | 157 | 16KB | 0 |
| g2u1 | 2 | 1 | 137 | 16KB | 0 |

（第一版用 `h8 s[PP]` 数组搬运，进了 scratch 48～144B，已弃，改显式寄存器。）

## 3. 单核计时（jobbench，每 job 128 次×7 轮中位；输出 f32 与 base golden 逐字节比，10 组全部 different=0）

| µs | base | u4 | u2 | u1 | g2u2 | g2u1 |
|---|---:|---:|---:|---:|---:|---:|
| 900（1504 token）批1 | 15.34 | 15.74 | 15.98 | 15.51 | — | — |
| 900 批2 | 15.34 | 15.69 | 28.25* | 15.58 | 16.10 | 16.72 |
| 900 批3 | 15.37 | 15.75 | 16.02 | 15.55 | 16.31 | 15.78 |
| 1080（2160 token）批1 | 21.18 | 21.10 | 19.83 | 19.71 | — | — |
| 1080 批2 | 20.95 | 20.25 | 19.97 | 20.72 | 22.32 | 22.26 |
| 1080 批3 | 20.85 | 20.11 | 20.34 | 21.38 | 21.90 | 23.18 |

\* 单次异常值。900 所有变体都比现役慢（最好 u1 +1.2%）；1080 G=4 快 1～6% 但各变体批间排名不稳，折整帧 13 次约 −0.005～−0.015ms，同时 900 +0.002～+0.005ms——不满足"另一档不变差"。

## 为什么不赚

- 权重 512×512 half 512KB，13 块全在 L2；省的是 L2 请求，不是 DRAM（与 C512 投影 M32 负账同源）。W5 在 ViT QKV 赚是因为那里每 WMMA 1.5 条 global 读、L0/TA 先到顶；mix 的 A 本身是 f32（每 K16 两条 b128），B 共享后 A 仍占一半以上请求，瓶颈没挪开。
- 900 只有 47 个 32-token 片：G=4 → 96 个 4-wave 组摊 64 CU，一半 CU 拿 2 组一半拿 1 组，加上组内 barrier 同步，尾巴比 376 个单 wave 均匀摊长；1080 68 片 → 136 组，摊得较匀，所以略赚。
- VGPR 102→121～198（kk 展开越多越涨），占用率不是主因（总 wave 数只有几百）。
- 要追 Daniel 这条链，方向是**数据形态**（mix 入口 A 从 f32 变窄 / 三核合一让 hidden 不落 global），不是组内共享；A 变 half 的入口问题见 `../c512-mix-20260927`（packed 张量还被 projection 作残差读，有 shift/identity 两类生产者）。FP8 激活属有损，C 段。

## 文件

`micro-jobs.json`（job 定义）、`micro-logs.zip`（三批原始日志）。复现 `Development/HIP/experiments/c512-ffn-lds/`（build.ps1 → make-jobs.py + kernel-map/pack-jobs.py → micro.ps1）；lab `D:\DLSSNR-Lab\hip-backend\c512-ffn-lds-20260930`。模块 hash（gfx1201，含嵌入源，不作逐字节依据）：g0 945c217a、u4 221b5afd、u2 7b976720、u1 d47a306c、g2u2 5169a853、g2u1 1c9dd823。

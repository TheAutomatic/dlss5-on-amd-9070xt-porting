# 有损 fast 档（2026-10-01，光派单，Zero 已批"损失点儿画质换吞吐"）：只测不装

**结论先行**：fast 配方 = `CW_FAST_NUM 3`（C32）+ `W2_FAST_NUM 3`（c64-wave2）+ `HIP_DEC_F8W 1`（逐位）+ `DLSS5_NETWORK_1080_ROWS=1088`。三轮 ABBA：**900 −0.107～−0.113ms（7.242→7.131），1080 −0.56～−0.60ms（9.956→9.366）**，p99 两档每轮都更好。对现装逐位版本的 PSNR：**最差 51.8 dB（单帧），各 case 均值 52.8～55.5 dB**。默认档不变：所有宏默认 0，宏为 0 重编与 HEAD 源码 `.text/.rodata/.note` 逐字节相同；宿主只多了一个按导出探测的分支（模块里没有 `_ks2` 就走原路）。

## 1. 逐项表（基准 = 剑星现装 31 模块 + e22d15a2 宿主；候选 = 同宿主源 + 本分支；3 轮 ABBA，每轮 1000 帧弃 200；PSNR = 8-bit ppm，7 case × 12 帧，对现装逐位输出）

| 项 | 开关 | 900 三轮 ms | 1080 三轮 ms | PSNR 最差帧 / case 均值范围 | 判断 |
|---|---|---|---|---|---|
| C32 快路径 | `CW_FAST_NUM 3`（Hrtz 恒等 = f32 激活/归一化，softmax 1/sum 只用 rcp） | −0.116 / −0.079 / −0.089 | −0.126 / −0.148 / −0.141 | 52.0 / 53.2～55.7 | **进 fast** |
| ViT attention 拆 key（2 wave/组，LDS 合并） | `HIP_VIT_ATTN_KSPLIT 1` | +0.009 / +0.004 / +0.020 | +0.044 / +0.052 / +0.042 | 55.5 / 66～∞ | 不进（变慢） |
| 中间块 C64/C128 f32 快路径 | `W2_FAST_NUM 3`（H/Hrtz 恒等，w2_inverse 只用 rcp），c64-wave2 | −0.030 / −0.017 / −0.027 | −0.027 / −0.025 / −0.047 | 53.6 / 54.5～56.0 | **进 fast**（小） |
| 同上，C256 | `W2_FAST_NUM 3`，swin-persistent | +0.008 / +0.007 / +0.017 | +0.016 / −0.001 / −0.014 | 54.5 / 54.8～∞ | 不进（持平） |
| decoder Up fp8（逐位） | `HIP_DEC_F8W 1` + `DLSS5_IO_FUSE=1` | +0.004 / −0.005 / −0.012 | −0.006 / +0.010 / +0.031 | **35.2**（非时序 case；history ∞） | 见 §3 |
| 1088 行 | `DLSS5_NETWORK_1080_ROWS=1088` | ±0.02 | −0.455 / −0.442 / −0.450 | 53.5（只 1080 case） | **进 fast** |
| **fast 配方合并**（CF+MF+F8W+1088） | — | **−0.113 / −0.107 / −0.112** | **−0.605 / −0.601 / −0.562** | **51.8 / 52.8～55.5** | — |

另一版合并（加 KS、MS）：900 −0.108/−0.114/−0.111，1080 −0.556/−0.562/−0.567，比上表略差，印证 KS/MS 不赚。对照：flat-A + HEAD 重编 deep_fast（H 组）7 case 全逐位相同。

PSNR 逐 case（fast 配方）：900-static 53.30、900-motion 53.26（最差帧 52.45）、1080-static 52.79、1080-motion 52.96（52.20）、720-motion 53.07（51.83）、900-history 55.46、1080-history 54.70。参照：fidelity-ngx 下我们全 71 块对 NVIDIA 47.43 dB，所以 fast 档相对逐位版的 ~53 dB 偏差约是我们与 NVIDIA 距离的 1/4 能量，预计对 NVIDIA 下降 <1 dB；**对 NVIDIA 的同口径复测没做**（要 Style0 测量版模块另编一套，留给 Zero 决定是否需要）。

## 2. 与 mochizuki
现基准（这台机这轮）900 7.24 → fast 7.13ms，他 6.02；1080（1088 行）fast 9.37ms，他 7.81。差距从 1.22/2.15 缩到 1.11/1.56ms。剩下的主体是 C512（+332/+492µs，组织方式）和 C32 里尚未拿的 f16 成对算术，不是 fast 开关能补的。

## 3. 注意
- **`DLSS5_IO_FUSE=1` 在本 harness 下改了输出**：非时序 case 对现装 35 dB（只开 F8W 不开它时，F8W 逐位）。input-slim 当时判 19 SAME，可能是那次两边都开了或宿主版本不同；本轮没追，fast 配方**不带 IO_FUSE**，需要另查后再说。
- KS 慢的原因（推断）：64 线程组 + 末尾屏障/LDS 合并的开销抵掉了链长减半；和 M32、TM 负账同向——这个核在当前占用下并行度并不缺，瓶颈另有所在。
- `HIP_DEC_WIDE` 与 `HIP_DEC_F8W` 在宿主里互斥（`_w` 先选中后 f8 判断不成立），按派单取 F8W。
- 现装 deep_fast-packed（EEC7D4A6）与 HEAD 源码重编（320BB15E）三段不同（同长度），本分支宏 0 与 HEAD 重编逐字节相同；其余 c32-wave1、c64-wave2、swin-persistent 宏 0 与现装逐字节相同。

## 文件
源码：`hip/c32_fused_ffn_attention.hip`（`CW_FAST_NUM`）、`hip/multihead_fast_padded.hip` + `hip/wave_owned_mh.inc`（`W2_FAST_NUM`）、`hip/deep_fast.hip`（`HIP_VIT_ATTN_KSPLIT`，不进配方）；宿主 `Development/HIP/hip_reference_network.h`（`_ks2` 导出探测）。build-modules.ps1 配方未改：fast 档 = `-ExtraDefines 'CW_FAST_NUM 3','W2_FAST_NUM 3','HIP_DEC_F8W 1'` 重编 c32-wave1/c64-wave2/deep_fast-packed + flag `DLSS5_NETWORK_1080_ROWS=1088`。脚本 `Development/HIP/experiments/fast-tier/`；原始输出 `all{1,2,3}.log`、现装哈希 `installed.txt`。lab `D:\DLSSNR-Lab\hip-backend\fast-tier-20261001`（帧转储已删）。没装机，游戏文件没动。

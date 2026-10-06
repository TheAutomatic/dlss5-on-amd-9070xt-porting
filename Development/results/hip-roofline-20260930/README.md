# HIP 段实测 vs 理想（roofline）：900 / 1080（2026-09-30，只测只算，未改生产）

**结论先行**：不算跨 API 交接，HIP 段（输入等待之后第一个网络核开始 → 输出拷贝结束，hipEvent）实测 **900 7.256ms、1080 10.065ms**（中位，各 ~1600 帧）。其中逐核独立时间之和 **6.827 / 9.701ms**，输出 hipMemcpy **≈0.035 / 0.045ms**，剩下的**核间空隙（派发/barrier/PDL 等待/冷缓存）≈0.39 / 0.32ms**，约每派发 2.4 / 2.0µs。按 9070 XT 网络内实际频率 2.75GHz 的 FP8/F16 WMMA 峰值，整网纯算力下限 **2.16 / 3.09ms**，纯访存下限（权重一次 + 块边界激活，现有格式，DRAM 620GB/s）**1.55 / 2.11ms**，所以**理想 = 算力下限 2.16 / 3.09ms**，实测是它的 **3.36 / 3.26 倍**。计入"FP8 WMMA 与 VALU 不重叠 + 必要的量化/softmax/激活/归一化 VALU"的**现实理想约 4.19 / 6.01ms**，实测是它的 **1.73 / 1.67 倍**，差 **3.07 / 4.06ms**：核内超出现实理想 2.64 / 3.69ms（大头 C512 0.83 / 1.15、ViT 0.51 / 0.78、C32 0.42 / 0.61、C256 0.40 / 0.44），空隙 0.39 / 0.32，拷贝 0.04。**访存不是整网瓶颈**；离理想最远的是 token 少的两族（C512、ViT，≈3 倍）。

## 1. HIP 段实测

- 现装：剑星 add-on 6d059845 同源宿主（kernel-map-v3 的 `benchmark-base.exe`，HEAD 源码）+ 剑星现装 31 个 gfx1201 模块（相对 kernel-map-v3 变了两个：`c512-m32-mh` 4BB9B847→0F28A38C、`deep_fast-packed` 7FFAA65F→EEC7D4A6，即 c512-av-f 与 f-sweep 两刀）。flags 同 kernel-map-v3 record.ps1（SWIN_RUN1 / PDL1 / DIRECT_IO3 / BENCH_PLAIN1 / graph off，NativeGameFrame 回放，1000 帧弃 200）。
- HIP 段 = 现有 `DLSS5_HIP_SPAN_PROBE=1`（桥接里：输入 fence 等待之后记 begin，`network->Enqueue`（RunGraph 162/158 派发 + 输出 `hipMemcpyAsync` D2D 12B/px）之后记 end）。**注意这个开关要写进 flags 文件**（benchmark 会按 flags 文件重置 DLSS5_ 环境变量，只设环境变量不生效——frame-breakdown-20260928 说"没输出"就是这个原因）。
- 核和 = kernel-map-v3 的 jobbench 逐派发中位数（8 warmup、128 次图捕获、7 轮中位），两个变了的模块的 65+65 个派发用现装模块重测（`rejobs.log`；900 这部分 1287→1219µs，1080 2075→1804µs，1080 的差里含 kernel-map-v3 那 5 个间歇慢派发这次都回到常态）。sp_run256_w16 仍是事件法估计（与 v3 同）。

| | 900 | 1080 |
|---|---:|---:|
| 派发数 | 162 | 158 |
| HIP 段 span 中位 / 均值 / p99（ms，两轮合并） | **7.256** / 7.253 / 7.648 | **10.065** / 10.064 / 10.487 |
| 整网回放 wall（无探针，两轮均值） | 7.551 / 7.606 | 10.413 / 10.458 |
| wall − span（≈跨 API 交接 + D3D 编解码，另算） | ≈0.32 | ≈0.37 |
| ① 逐核独立时间之和 | **6.827** | **9.701** |
| ② HIP 侧拷贝（输出 D2D，按 bw 实测 17.6/25.3MB） | 0.035 | 0.045 |
| ③ 空隙 = span − ① − ② | **0.395**（2.4µs/派发） | **0.319**（2.0µs/派发） |

读法：③ 是"在网络里跑"比"单独热跑"多出来的全部——派发与 barrier、PDL 等待、以及 jobbench 热缓存 vs 网络里冷权重/冷激活的差。没有硬件计数器，拆不开这三样。事件法逐派发打点（`evprof.exe`，`prof-*-kev.txt.gz`）在 PDL/any-order 派发下会串行化并出负值（整帧被拉到 13.2 / 16.2ms），**不能用来拆空隙**，只留作证据。

## 2. 实测带宽（`bw.exe` / `bw.hip`，hipEvent，31 次中位）

| 足迹 | 读 GB/s | 写 GB/s | 拷贝（读+写）GB/s | hipMemcpy D2D（读+写） |
|---|---:|---:|---:|---:|
| 128MB～1GB（出 64MB MALL） | 592～630 | 540～618 | 540～590 | 564～578 |
| 48MB | 1270～1690 | 1200～1695 | ~560～590 | 588 |
| 16～25MB | 1.2～2.6 TB/s | 1.1～2.3 TB/s | 1.1～1.9 TB/s | 1070～1830 |

DRAM 可达约 **620GB/s 读 / ~600 写**（标称 640）。块边界张量里 1080 的 C32 全分辨率 E4M3 是 71MB、900 是 49MB，处在 MALL 边上；访存下限统一按 DRAM 620GB/s 算（偏保守）。

## 3. 理想值（roofline，`roofline.py` → `roofline.json`）

**模型，不是计数器。** 块表、窗口补边（C32 按移位补 (w+2sx)(h+2sy)；C64+ 补到 8 的倍数，900 C512 即 56×32/40）、1080 的 1152 行、跳块 42/43/46、ViT 400/640 token，都沿用 `results/9070-theoretical-20260921/estimate.py` 并逐项核对了现役 flags；精度按现役核：C512 mix/分组扩展、ViT QKV、down/up、输入头 FP16，其余主矩阵 FP8，RGB 头 FP32。对角残差模拟 MMA、零 lane 等指令级冗余不计（它们是"实现代价"，不是必要工作）。

**峰值**：AMD 规格 64CU、2.97GHz boost、dense FP8 389 TFLOPS、dense FP16 195（= 每 CU 每周期 FP8 2048 FLOP / FP16 1024 FLOP）。实际频率用 `results/clock-ledger-20260924`（功耗墙 325W 下整网 1080 2.75GHz、900 2.78～2.83，ADL 遥测）：按 **2.75GHz → FP8 360 / FP16 181 TFLOPS**。若按 2.97 标称，下限再乘 0.93。VALU：64CU×2 SIMD32×32 lane×1 指令/周期（不计 VOPD 双发）= 11.3T lane-op/s。

| | 900 | 1080 |
|---|---:|---:|
| FP8 WMMA GFLOP / FP16 / FP32 | 681.7 / 46.5 / 0.3 | 977.0 / 66.5 / 0.4 |
| **纯算力下限（WMMA 满峰）** | **2.16ms** | **3.09ms** |
| 必要 VALU（模型，G lane-op） | 22.9 → 2.04ms | 32.9 → 2.92ms |
| 权重（每帧读一次，FP8/FP16 实际格式） | 170MB | 170MB |
| 块边界激活 + 跳连 + 输入输出（E4M3 / f32 io） | 788MB | 1137MB |
| **纯访存下限**（上两行 / 620GB/s） | **1.55ms** | **2.11ms** |
| 完全融合的绝对访存下限（权重 + io） | 0.38ms | 0.43ms |
| **理想 = max(算力, 访存)** | **2.16ms** | **3.09ms** |
| **现实理想 = WMMA + VALU（不重叠），访存被掩盖** | **4.19ms** | **6.01ms** |

- VALU 模型每元素的最少 lane-op：每个矩阵输出重新量化到 FP8 约 3（乘 scale、夹紧、打包转换摊销），softmax 每个分数约 5（减 max、exp、累加、乘倒数、转 FP8），FFN 隐层激活约 6，归一化+残差每元素约 5；头维按 32 计。这组系数是**下限量级的估计（±50%）**，C32（通道少、逐元素开销相对 MAC 最大）受它影响最大。
- 权重 170MB 里 ViT 占 126MB（FFN FP8 67MB、QKV FP16 50MB），C512 29MB。宿主权重缓冲按 f32 分配、FP8 字节原地打包，分配大小是实际读取的 4 倍，这里按实际读取算。

## 4. 差距拆账

| | 900 | 1080 |
|---|---:|---:|
| 实测 HIP 段 | 7.256 | 10.065 |
| ÷ 理想 | 3.36× | 3.26× |
| ÷ 现实理想 | 1.73× | 1.67× |
| 超出现实理想 | 3.07ms | 4.06ms |
| 其中 空隙（③） | 0.39 | 0.32 |
| 其中 输出拷贝 | 0.04 | 0.05 |
| 其中 核内（① − 现实理想） | 2.64 | 3.69 |

按族（`families.json`；实测 = 该族独立核和；现实理想 = max(WMMA+VALU, 访存)，单位 µs）：

| 族 | 900 实测 | 900 现实理想 | 倍数 | 1080 实测 | 1080 现实理想 | 倍数 | 限制项 |
|---|---:|---:|---:|---:|---:|---:|---|
| C32 | 2197 | 1781 | 1.23 | 3172 | 2560 | 1.24 | VALU（模型里 VALU 1.2/1.7ms > WMMA 0.56/0.81） |
| C64 | 773 | 542 | 1.42 | 1084 | 778 | 1.39 | VALU≈WMMA |
| C128 | 778 | 542 | 1.44 | 1184 | 774 | 1.53 | WMMA |
| C256 | 951 | 555 | 1.71 | 1222 | 785 | 1.56 | WMMA |
| C512 | 1245 | 419 | **2.97** | 1676 | 528 | **3.17** | WMMA |
| ViT | 829 | 316 | **2.63** | 1307 | 528 | **2.48** | WMMA（权重 126MB 读 0.2ms） |
| 头/解码 | 54 | 31 | 1.8 | 54 | 45 | 1.2 | — |

- **访存**：没有一族被访存卡住（各族访存下限都小于 WMMA+VALU）；逐核 x_floor（kernel-map-v3）接近 1 的只有 `mh_attention_project_frag_c512`、ViT contract/expand、split_ffn/mix、C32 chain，这些是局部的。
- **VALU**：C32/C64 在模型里 VALU ≥ WMMA，而且 RDNA4 上 FP8 WMMA 与 VALU 不重叠，所以 C32 离"现实理想"只有 1.23 倍、离"纯算力理想"有 3.9 倍——C32 剩下的主要是 VALU 条数本身。
- **占用率 / 尾效应**：C512（900 1500 token、1080 2160 token，13 块 × 7 派发）和 ViT（400/640 token）行数少，一次派发的 wave 数撑不满 64CU×2SIMD 或只有一两轮，尾部与每派发固定开销占比大；这两族是离理想最远（≈3 倍）、绝对差也最大的（合计 1.34 / 1.93ms）。没有计数器，无法把这部分再拆成"占用"与"指令"。
- **空隙**：约 2µs/派发 × 160 ≈ 0.3～0.4ms。PDL 已开；再省只能靠减派发（融合/持久化）。
- **频率**：理想按 2.75GHz 算；功耗墙把网络压在 2.75～2.8，而规格 2.97。不计入"差距"，但它是同一张卡上真实存在的 7% 上限。

## 5. 与 Daniel 同口径

- 逐核独立时间之和（jobbench 同 harness）：900 我们现在 **6827µs**；Daniel 0.5.0 reference 900（09-30 上午 kernel-map-900，154 派发）8171.6µs，扣掉他跑、我们跳的 42/43/46 共 12 派发后 7882.7µs。1080 同几何不可比（他 1088 行）。
- 整网：他日志里的 network（HIP 计时）1080 fast 档 9.4～10.0ms、reference 11.0ms，1088 行；我们 HIP 段 1152 行 10.065ms。按行数比 1088/1152 粗折约 9.5ms，与他 fast 档同量级；我们是 reference 同类精度（NVIDIA 位移、完整 1152 行、逐位基准）。

## 6. 剩余机会（我们的判断）

1. **C512 + ViT 的组织方式**（差现实理想 1.3～1.9ms）：少 token 大通道，瓶颈是每派发的波数与尾部、以及多派发链（C512 每块 7 核）。方向是 Daniel 式的整块融合/多组 token 共用权重（C256 已证明组织方式对了会赚），不是再压数据格式。
2. **C32 的 VALU 条数**（差 0.4～0.6ms）：WMMA 只占 C32 的 1/4；删量化/打包/噪声生成里的指令仍然 1:1 兑现。
3. **派发空隙**（0.3～0.4ms）：减派发数（162/158）。
4. 访存方向基本见底；频率受功耗墙（让 FFN 族更省电能抬全帧时钟，见 clock-ledger）。

## 文件

`ledger.json`（span/核和/空隙）、`families.json`（逐族）、`roofline.json`（模型输出）、`bw.log`、`rejobs.log`、`{wall,wall2,span,span2}-{900,1080}.csv`、`span*-*.err.gz`（逐帧 hip_span）、`prof-*-kev.txt.gz`（事件法逐派发，不可用于拆账，见 §1）。脚本 `Development/HIP/experiments/hip-roofline/`（setup/run/all/rejobs.ps1、bw.cpp/bw.hip、roofline.py、analyze.py、relist.txt）。lab `D:\DLSSNR-Lab\hip-backend\hip-roofline-20260930`（帧转储已删）。

## English summary for TheAutomatic

**HIP-only latency (no cross-API handoff).** Measured with hipEvents on the network stream: begin after the D3D→HIP fence wait, end after the network (162 dispatches at 900 / 158 at 1080) and the HIP-side D2D copy of the RGB output. Current installed build (host 6d059845, 31 gfx1201 modules), RX 9070 XT, NativeGameFrame replay, 1000 frames, first 200 dropped, 2 runs:

| | 900 (1600×960) | 1080 (1920×1152) |
|---|---:|---:|
| HIP segment, median (p99) | **7.256 ms** (7.65) | **10.065 ms** (10.49) |
| sum of per-kernel isolated medians (jobbench, warm) | 6.827 | 9.701 |
| HIP-side output copy (D2D) | ~0.035 | ~0.045 |
| inter-kernel gaps (launch/barrier/PDL waits/cold caches) | 0.395 (~2.4 µs/dispatch) | 0.319 (~2.0 µs/dispatch) |
| full replay wall incl. handoff + D3D codec (for reference) | 7.55–7.61 | 10.41–10.46 |

**Roofline (analytic model, no HW counters on Windows).** Principal matmuls counted at actual padded shapes (window/shift padding, 1152 rows at 1080, skipped blocks 42/43/46, ViT 400/640 tokens), 2 FLOP/MAC: 900 = 682 GFLOP FP8 + 46 GFLOP FP16; 1080 = 977 + 67. Peak: AMD spec 389 TFLOPS dense FP8 / 195 FP16 at 2.97 GHz (64 CU), scaled to the in-network clock we measured under the 325 W power limit (~2.75 GHz) → 360 / 181 TFLOPS. Measured DRAM bandwidth: ~620 GB/s read, ~600 write, ~570 GB/s for hipMemcpy D2D (footprints under the 64 MB Infinity Cache run at 1.2–2.6 TB/s).

| | 900 | 1080 |
|---|---:|---:|
| compute floor (WMMA at peak) | 2.16 ms | 3.09 ms |
| memory floor (weights once 170 MB + block-boundary activations in current FP8/E4M3 formats + f32 I/O, at 620 GB/s) | 1.55 ms | 2.11 ms |
| **ideal = max** | **2.16 ms** | **3.09 ms** |
| minimal VALU (requant, softmax, activation, norm; model ±50%) | ~2.0 ms | ~2.9 ms |
| **realistic ideal = WMMA + VALU (they do not overlap on RDNA4), memory hidden** | **~4.2 ms** | **~6.0 ms** |
| measured / ideal | 3.4× | 3.3× |
| measured / realistic ideal | 1.7× | 1.7× |

**Where the remaining ~3.1 ms (900) / ~4.1 ms (1080) goes:** inter-kernel gaps 0.39 / 0.32 ms; output copy 0.04; the rest is inside kernels. By family (measured vs realistic ideal): C512 1.25 vs 0.42 ms (3.0×) and ViT 0.83 vs 0.32 ms (2.6×) are the furthest — few tokens (1500–2160 and 400–640), so waves-per-dispatch, tails and the per-block kernel chain dominate; C256/C128/C64 are 1.4–1.7×; C32 is only 1.2× of its realistic ideal but VALU-bound (WMMA is ~1/4 of its time). Nothing is DRAM-bound at the network level.

**Remaining opportunities as we see them:** (1) reorganise C512/ViT (whole-block fusion / several token groups sharing one weight fetch — the change that paid off for C256), worth up to ~1.3–1.9 ms; (2) fewer VALU instructions in the C32 prefix/post/chain kernels (~0.4–0.6 ms; on RDNA4 every removed VALU instruction is time saved); (3) fewer dispatches (~0.3–0.4 ms of gaps at ~2 µs each; PDL is already on); (4) the power-limited clock (2.75 vs 2.97 GHz) is a further ~7% headroom that only lower-power kernels can reclaim. Memory-format work is essentially exhausted. For reference, same-harness per-kernel sum at 900: ours 6.83 ms vs Daniel 0.5.0 reference 8.17 ms (7.88 ms without the blocks we skip).

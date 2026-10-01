# 网络前后 D3D 段瘦身（input-slim，2026-10-01）：拆账 + 一刀 IO_FUSE，逐位、avg 六轮全正，但 900 p99 不过，不收、不装

**结论先行**：DIRECT_IO=3 之后，网络前后留在 D3D 上的活一共只有 **900 约 94µs、1080 约 123µs**（离线回放，GPU 时间戳逐段），其中还有 8µs 是回放特有的最终拷贝（游戏里 bit 2 已免）。最大的一段是 decode（36/44µs，真计算，不能删），其次 input（23/33µs，写 35MB 共享输入）、neural（16/22µs，f32 输出→RGBA16F 纹理）、encode（11/15µs）。"网络外 0.3ms"里剩下的大头是交接（见 `same-queue-20261001`），不是这些 pass。

动了最干净的一刀：**`DLSS5_IO_FUSE=1`**——decode 直接读网络 f32 输出缓冲（做同样的 f32→f16 舍入），跳过 neural pass。19 组 SAME，六轮 ABBA avg 全部变快（900 −0.004～−0.020、1080 −0.012～−0.035ms），但 **900 合并 p99 7.791→7.811（+0.020）**，六轮里 3 轮 900 p99 变差；1080 p99 10.617→10.594 变好。按验收"p99 三轮合并不变差"不收：开关留在源码、默认 0、不进模板、不装机、不打包。

## 1. 每一步多少 µs（`DLSS5_GAME_PROBE=1`，新增细分打点；每帧 Flush，所以是串行化后的纯 GPU 时间；600 帧，后 500 帧均值）

| 步 | 做什么 | 900 | 1080 |
|---|---|---:|---:|
| encode | `low` → 编码 RGBA16F 纹理（sRGB 曲线） | 11.0 | 15.1 |
| input | 编码纹理 → HIP 共享输入 f32（含镜像补行，35MB@1080） | 23.3 | 32.7 |
| network | 交接 + HIP 网络 | 7190 | 9890 |
| neural | 网络 f32 输出 → RGBA16F 纹理 | 15.7 | 22.2 |
| decode | 原图 + proxy + neural → 输出（Lab 色相、比例） | 35.9 | 43.6 |
| copy | decode 输出 → 目标纹理（回放特有；游戏 DIRECT_IO bit 2 已免） | 8.3 | 8.3 |
| （游戏内另有）颜色 → `low` 整拷 | pre-upscale `CopyTextureRegion`，16.6MB | 回放测不到，按同尺寸拷贝估 ≈8 | ≈8 |

D3D 段合计（不含 network）：900 ≈94µs、1080 ≈122µs；游戏内（加 `low` 拷、减最终拷贝）大致相同。原始日志 [probe.txt](probe.txt)。

## 2. 候选与取舍

| 候选 | 省什么 | 估计 | 逐位 | 处理 |
|---|---|---|---|---|
| **N：neural 并进 decode**（`DLSS5_IO_FUSE=1`） | 一个 dispatch＋一次 26.5MB 读 / 16.6MB 写；decode 改读 f32（多读约 10MB） | 900 ≈−0.013、1080 ≈−0.02 | 是（f16tof32(f32tof16) 与纹理存储同舍入，实测 SAME） | 做了，见下 |
| E：encode 并进 input | encode 纹理写＋读（2×16.6MB）与一个 dispatch；pow/exp 算量不少 | ≤−0.01 | 应可 | 未做：decode 仍要 proxy 纹理（或改读 35MB f32 输入缓冲，读量翻倍），净收益近零；input 的 root signature/cbuffer/FIT/SRGB/曝光变体都要复制一套 |
| C：去掉颜色 → `low` 整拷，encode 直接读游戏颜色 | 16.6MB 拷贝 ≈8µs | ≈−0.008 | 应可 | 未做：只在游戏内路径，离线测不出；且要每帧重绑 encode/decode 源（游戏颜色可能轮换），还有 async 延迟提交下颜色是否仍有效的风险。方案见 §4 |
| 交接 | — | 0.15～0.19 上限 | — | 见 `same-queue-20261001`，停线 |

## 3. IO_FUSE 实测（`full.ps1`：7 用例×EXACT/AE×12 帧 + AE CSV + 900/1080 票号回绕 = 19 组；ABBA 1000 帧弃 200）

- 基线 = `benchmark-base.exe`（main HEAD 源码）+ 剑星现装 31 模块 + 游戏现装 assets；候选 = `benchmark-P.exe`（本分支）+ 新 `native_codec_decode.hlsl` + flags 加 `DLSS5_IO_FUSE=1`；模块同一套。
- 逐位：19 组全 SAME（[regression.txt](regression.txt)）；日志里 22 次 `detail=io_fuse`（非历史用例全部启用；历史用例按设计不启用，也 SAME）。

| 轮 | 900 avg | 900 p99 | 1080 avg | 1080 p99 |
|---|---|---|---|---|
| 1 | 7.5424→7.5255（−0.017） | 7.749→7.722 | 10.2860→10.2650（−0.021） | 10.617→10.579 |
| 2 | 7.5753→7.5716（−0.004） | 7.770→**7.806** | 10.3001→10.2656（−0.035） | 10.620→10.609 |
| 3 | 7.5767→7.5568（−0.020） | 7.787→7.778 | 10.3198→10.2858（−0.034） | 10.654→10.613 |
| 4 | 7.5134→7.4933（−0.020） | 7.757→7.742 | 10.2823→10.2701（−0.012） | 10.567→10.559 |
| 5 | 7.5792→7.5609（−0.018） | 7.841→**7.909** | 10.2938→10.2761（−0.018） | 10.596→10.578 |
| 6 | 7.5754→7.5622（−0.013） | 7.804→**7.828** | 10.3019→10.2758（−0.026） | 10.611→10.608 |
| 合并 | 7.5604→7.5450（−0.015） | 7.791→**7.811** | 10.2973→10.2731（−0.024） | 10.617→10.594 |

前三轮合并 900 p99 7.772→7.778，加测三轮后 7.791→7.811，两次都略差，不是一轮的偶然。可能原因（未查实）：decode 改读 f32（12B/px）比读 f16 纹理（8B/px）多约 10MB 访存、且是非纹理路径，尾帧受影响。**按规则不收**；若 Zero 认为 avg 稳定为正、900 p99 +0.02 可接受，开关已在，模板加一行即可。

## 4. 游戏内怎么测（离线测不出的部分，需 Zero 在场，不自己进游戏）

目的：(a) 颜色→`low` 整拷在游戏里实际多少；(b) IO_FUSE 在游戏内画面是否正常。
1. 剑星本机（不走 Splashtop），1080P 窗口、FSR 原生 AA、EXACT。flags 临时加 `DLSS5_GAME_PROBE=1`（每帧 Flush，会掉帧，只用来读分段），站立 30 秒退出；`DLSS5-AMD\logs\native-game-probe.txt` 给出 encode/input/network/neural/decode/copy 各段 µs。
2. 同时要 `low` 拷贝那段，需要在 `native_pre_upscale.h` 拷贝前后再打两点——属于新诊断代码，本轮没写；按 §1 同尺寸估 ≈8µs，价值不大，建议不做。
3. IO_FUSE 画面验收（若 Zero 决定收）：装本分支 add-on（`scripts/build-addon.sh … --hip`，本轮已编 `2584e82a…`，未装）+ 新 `native_codec_decode.hlsl`，flags 加 `DLSS5_IO_FUSE=1`，看画面正常、F6 切换无异常；删 `DLSS5_GAME_PROBE`。

## 文件

- 代码（commit 见 DevHistory）：`src/native_game_codec.h`（`UseNeuralBuffer`，root SRV t5）、`shaders/native_codec_decode.hlsl`（`NATIVE_CODEC_NEURAL_BUFFER`）、`src/native_game_frame.h`（`DLSS5_IO_FUSE`、跳过 neural pass；`DLSS5_GAME_PROBE` 细分打点）、`scripts/CONFIGURATION.md` 追加一行。模板未改；RE9 runtime 不走 NativeGameFrame，不适用。
- 脚本 `Development/HIP/experiments/input-slim/`（setup/assets/probe/regression/full/go/go2/summarize/p99m、`gpulock.sh`）。lab `D:\DLSSNR-Lab\hip-backend\input-slim-20261001`（帧转储 6.2GB 已删）。
- 游戏文件、装机版本未动。

## 更正 / 复核（2026-10-01 午，fast-tier）
fast-tier 第一轮在"F8W + `DLSS5_IO_FUSE=1`"组看到非时序 case 只有 35 dB，曾怀疑本文的 19 组 SAME 是假的。复核结论：**本文 SAME 是真的，35 dB 是 fast-tier 测法的错**。IO_FUSE 必须配新的 `native_codec_decode.hlsl`（带 `NATIVE_CODEC_NEURAL_BUFFER`，md5 0C3CAABD，与 repo 相同；本文 `assets-cand`）。fast-tier 用的是 `assets-base`（旧 shader E5BB3862），宿主照样跳过 neural pass，旧 shader 不认 buffer，decode 读不到网络输出。复测（fast-tier lab `io.ps1`，同宿主同模块）：新 shader + IO_FUSE 对基准 7 case × 12 帧**全逐位相同**；旧 shader + IO_FUSE 900-static 12/12 帧不同。本文的基准一侧不带 IO_FUSE（只有候选带），不存在"两边都开"的问题。
- 由此记一条风险：IO_FUSE=1 搭配旧 decode shader 不会报错，只会悄悄出错图。若将来收它，宿主应在 shader 缺这个宏时拒绝启用，或者把 shader 和开关打包在一起发。

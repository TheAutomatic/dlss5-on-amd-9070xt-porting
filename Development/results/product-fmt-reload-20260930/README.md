# 产品侧：颜色格式兜底 + flags 热重载（2026-09-30，未装机，不改网络数值）

参照 mochizuki 0.0.2.4（`results/mochizuki-024-20260930`）。两条产品线都改，原来接受的格式一个比特不动。

## 1. 颜色格式兜底 `DLSS5_FORMAT_FALLBACK`（默认 1）

**现状（改前）**：add-on 只收 RGBA16F / RGBA16 typeless(Ronin UNORM) / RGBA8(含 SRGB、BGRA) / R11G11B10；RE9 runtime 另收 R9G9B9E5。其他格式：pre-upscale 路线状态行 UNSUPPORTED、原图直通 FFX（静默放过，日志只每 100 帧一句"unsupported low-res input"，不带格式）；RE9 `PrepareFrame: colour rejected ... fmt=<数字>`。

**新增表**（`src/native_format_fallback.h`，只在 `NativeIsGameColor` 说不时才查）：R9G9B9E5_SHAREDEXP（线性 HDR）、B8G8R8X8 UNORM/SRGB/TYPELESS、R10G10B10A2 UNORM/TYPELESS、R32G32B32A32 FLOAT/TYPELESS、R32G32B32 FLOAT/TYPELESS、R16G16B16A16_SNORM、R8G8B8A8_SNORM、B5G6R5、B5G5R5A1、B4G4R4A4。都是 GPU 能用 typed SRV 解成 float 的。

- **add-on（pre-upscale 路线）**：兜底格式时，原来的"同格式 CopyTextureRegion 到私有 low"换成一个 compute pass（`shaders/native_format_convert.hlsl` + `src/native_format_convert.h`，clamp 到 half 范围、NaN→0、无 alpha 格式写 1），low 分配成 RGBA16F，之后走原 RGBA16F 路线（DIRECT_IO bit2 也可用），交给 FSR 时 FFX 描述格式改 4=RGBA16F。原格式 `fallback_view==UNKNOWN`，代码路径与改前逐语句相同。着色器缺失（旧包）→ 只关兜底、记日志，不致命。
- **RE9 runtime**：兜底格式走 RGB9E5 自 0.28 就有的私有 FP16 输出路线，编码器 SRV 即转换（`SourceView`，旧格式仍是 `NativeViewFormat`）。
- **拒绝日志带格式名**：pre-upscale 首次 `colour format X (n) rejected ... / format fallback`；RE9 `fmt=NAME(n)`；codec/frame 异常信息带格式名。
- **不覆盖**：post-upscale / Magpie / XeSS 路线（结果写回游戏纹理，需要反向打包，未做）。

## 2. 热重载 `DLSS5_HOT_RELOAD`（默认 1）

`src/native_hot_flags.h`：每秒至多一次比 flags 文件修改时间，变了只重读 **DLSS5_STRENGTH**（add-on 全路线，解码混合，网络后）、**DLSS5_NOTICE / DLSS5_SHOW_FPS**（pre-upscale 状态行；NOTICE 从 0 热开时补建 overlay）。日志 `event=hot_reload`。其余键（高度/跳层/HIP 模块与内核开关/DIRECT_IO/PRE_UPSCALE/FIT/ASYNC/FRAME_STATS/FORMAT_FALLBACK）建缓冲、载模块或改网络数值，仍需重启。首次轮询只记时间戳，不改文件 = 逐位不变。
**默认开的理由**：可热改的三个键都不碰网络；不编辑无任何效果；开销一次 GetTickCount64/帧 + 一次 stat/秒；玩家边玩边调强度是主要用途（mochizuki 也默认开）。
**RE9 不适用**：强度/细节在 OptiScaler 菜单本来就是实时的；模板写明。

## 验证（9070，另一子代理结束后独占；日志 `smoke.log`）

- **add-on 宿主逐位**：HEAD(5b8d5dac) 编 benchmark vs 本改动编 benchmark，同模块 flat-F：7 用例 × EXACT/AE × 12 帧 = 168 帧逐帧 SHA **全 SAME**，AE 决策 CSV SAME。
- **RE9 runtime 逐位**：HEAD vs 新 runtime，RGBA16F 输入 900/1080 hash 同（b2980ada643da964 / 758674a8bbd0206d，与 09-29 同）；R9G9B9E5 新旧同 hash 6f41ba76。
- **新格式过整网（RE9 runtime，900，6 帧，出图）**：88/92/24/2/6/13/31/85/86/115 全部跑通、有 hash；HEAD runtime 对这些全部 `colour rejected`。B8G8R8X8 UNORM 与 TYPELESS 同 hash，R32G32B32A32 与 R32G32B32 同 hash（同数据同解码，符合预期）。输出图均值 0.450（RGB9E5）/0.450（BGRX8）/0.450（RGBA16F），无 NaN。
- **add-on 转换 pass（真 D3D12）**：14 个格式 1707×961 转 RGBA16F 与 CPU 解码对比全部在一个 half ULP 内（驱动 f32→f16 存储是截断，最大绝对误差 4.9e-4 @ 值≈0.9；RGB9E5 误差 0），X 格式 alpha=1。
- 未在游戏内实测（任务要求不装机）；pre-upscale 路线的 FFX 格式字段改动只能游戏里验。

## 产物（`D:\DLSSNR-Lab\product-fmt-20260930\`，未装机）

- add-on `dlss5-amd.addon64` 8b729f22f765e022df3b462766fc5de4820dfb1a08baf429a13205e1f3e74abc
- RE9 `LmxxfNrRuntime.dll` 99c8ead9a0088b03b49810476160f94e7c253b38af23ad9e666f633079e93eed
- `native_format_convert.hlsl` 35a1973fc558d7a934cc1190c91f026734405935113568c81e4c7b19c0627b90 —— **打包须新增到 native-game-tiled-assets**（package-037 的 shader 刷新只覆盖包里已有文件）。
- 模板：三个 `scripts/hip-*-flags.txt` 加两行；`scripts/CONFIGURATION.md` 两行。

复现：`Development/HIP/experiments/product-fmt/`（rt_fmt.cpp / convert_smoke.cpp / fmt_encode.h / run.ps1）。

# 1080 档紧凑几何 1088 行（可选档，有损，默认不开）（2026-09-30）

**结论**：新开关 `DLSS5_NETWORK_1080_ROWS=1088`（默认 1152）让 1080 档（固定 1080 或 auto 选中的 1080）按 1920×1088 算。**整网 −0.47/−0.48ms（4.42%/4.47%）**，比估的 0.70ms 少，因为 ViT 仍是同一个 32×20 网格（640 token），省的只有 Swin/解码器那 5.6% 的行。画质：对 1152 输出全帧 PSNR 约 **56dB**（8-bit 54～55.5dB），最大单像素差 20～48/255、只落在几十个像素（>16/255 的 9～44 个，都在画面中部高对比细节，不在边缘），>4/255 的像素 0.2%。底边 32 行比中部差（52.5～55.6dB vs 全帧 56），顶边 32 行与中部相当。**默认路径逐位**：不开时 168 帧 + 回绕 18 组 SAME，RE9 runtime 默认 1080/900 hash 与 09-29 相同。未装游戏、未发包，等 Zero 看数据决定是否进 0.38 作为可选档。

## 几何：1088 在每一级怎么整除

1088 = 2⁶×17（1152 = 2⁷×9；900 档 960 = 2⁶×15，也是 2⁶，所以走的是 900 档已验证过的同一套"非 2⁷"路径）。

| 级 | 1152 | 1088 | 处理 |
|---|---|---|---|
| /1…/16（C32…C256） | 1152…72 | 1088…68 | 全整除 |
| /32（C512，60 列） | 36 | 34 | 整除；token 数 60×34=2040 是 16 的倍数，`HIP_C512_PAD16` 不用补 |
| /64（ViT head） | 18 → 网格 32×20 | 17 → **同一个 32×20 网格，有效 30×17** | 多出的 3 行与 2 列是零 token，与 1152 的补法相同（只是少一行有效） |

输入补边：1080 行 + 8 行反射（`NativeRgbReflect` 原逻辑，1152 是 72 行反射）。post 位移不变（3，即 NVIDIA 的 (-4,-4)）。ViT 若按 900 档的"补到 16 的倍数"规则会得到 30×18=540（不是 16 的倍数），所以沿用 1920 宽的 32×20 特例。

## 代码（add-on 与 RE9 runtime 共用）

- `src/native_network_geometry.h`：`FromHeight(1088)={1920,1080,1920,1088}`；`DLSS5_NETWORK_1080_ROWS`（1152/1088，其它值报错）作用于固定 1080 与 auto；`DLSS5_NETWORK_HEIGHT=1088` 同义的固定档。`VitTokens()` 按 valid_height 仍 640。
- `Development/HIP/hip_reference_network.h`：几何白名单、`SwinRunCompatible`、C256 wave-owned 门、head `Down`（`h==36||h==34` → 32×20）加 1088。
- `src/native_post70.h`（D3D 路径几何检查）加 1088；`src/LmxxfNrRuntime.cpp` flags 白名单加 `DLSS5_NETWORK_1080_ROWS`。
- 模板三份写 `DLSS5_NETWORK_1080_ROWS=1152`＋注释；`scripts/CONFIGURATION.md` 一行（写明有损、与 NVIDIA 原版几何不同）。模块不变。

## 逐位（默认路径）

基线 = HEAD 源码（ec6c0199）的 benchmark-base，候选 = 加补丁的 benchmark-P / Proll，同一套剑星现装 31 模块（gfx1201）。7 用例 × EXACT/AE × 12 帧逐帧 SHA 同、AE 决策 CSV 同；900/1080 history × EXACT/AE 强制票号回绕同；18 组 SAME（`full.log`）。
RE9 runtime（rt_bench 1707×961，12 帧）：旧 20630dc7 与新 2d561e2d 在 1080 = 758674a8bbd0206d、900 = b2980ada643da964（与 09-29 相同）；新 runtime 设 `ROWS=1152` 同 hash；设 `ROWS=1088` 时 900 档不受影响（仍 b2980ada）；1080 → 1a963869e3697899、auto(1920×1080 输入) → 0a60c2b4354ed9bd，跑通；runtime-smoke 通过。

## 1088 路径自洽

`DLSS5_NETWORK_HEIGHT=1088` 与 `1080 + ROWS=1088` 逐帧同；1088 下 `SWIN_RUN=0 WAVE_OWNED=0`（旧通用路径）与快路径逐帧同（1152 对照同样 SAME）——说明快核在 34 行/17 行 token 上几何处理正确。SWIN_RUN 在 1088 下真的生效（`SP_STATS runs=24 fallback=0`，jobs 20304 vs 1152 的 21432）。`geom.log`。

## 整网 ABBA（1000 帧弃 200，1080-1088-1088-1080，同一 benchmark-P、同一模块）

| 轮 | 1152 ms | 1088 ms | 省 ms | 提升 |
|---|---:|---:|---:|---:|
| 1 | 10.7356 | 10.2612 | 0.4744 | **4.42%** |
| 2 | 10.7640 | 10.2828 | 0.4812 | **4.47%** |

## 画质（1088 对 1152，bench 输出 1296×720 RGBA f16，值域 0～1）

| 用例 | 帧 | PSNR（f16） | PSNR（8-bit） | 最大差 /255 | 顶 32 行 PSNR | 底 32 行 PSNR |
|---|---|---:|---:|---:|---:|---:|
| static | 0/5/11 | 56.01 | 54.14 | 38 | 59.18 | 52.50 |
| motion | 5 | 56.22 | 54.29 | 45 | 62.17 | 54.26 |
| motion | 11 | 56.49 | 54.40 | 48 | 60.07 | 52.57 |
| history | 5 | 56.29 | 54.79 | 20 | 56.01 | 52.75 |
| history | 11 | 57.10 | 55.50 | 24 | 57.62 | 55.60 |

平均绝对差：顶 32 行 0.0004、中部 0.0005～0.0006、底 32 行 0.0007～0.0011。最大差点在 (460～550, 712～745) 一带（画面中部），>16/255 的像素 9～44 个，全在 360～600 行。口径注意：是 bench 最终输出（1296×720），不是网络 1920×1080 内部网格；不含 8-bit 游戏管线之外的后处理。对照：900 档当初 1024→960 行差 31.5dB（`1910bdc8`），这次 1152→1088 温和得多。**是否"看得见"请 Zero 用 ppm 对看**：`D:\DLSSNR-Lab\geom1088-20260930\geom\{static,motion,history}-{1152,1088}\rgb-frame-*.ppm`。

## 与 Daniel / mochizuki 做法的差异

| | NVIDIA / 我们默认 | 我们 1088 档 | Daniel 0.5.x | mochizuki |
|---|---|---|---|---|
| 1080 工作尺寸 | 1920×1152 | 1920×1088 | 1920×1088（ceil64 "原生 extent"，`DLSSNR_EXTENT`） | 1920×1088 |
| 补边 | 72 行反射 | 8 行反射 | 未拆（其它尺寸他自注"single-tile mode not ported"） | `occ_pad.glsl`，未细拆 |
| ViT 网格 | 32×20，有效 30×18 | 32×20，有效 30×17 | 未拆 | 未拆 |
| post 位移 | 3（(-4,-4)） | 3（不变） | 0 | — |

我们只改行数、别的全保持 NVIDIA 原样；Daniel 同时把 post 位移改成 0，是两处偏离。

## 产物（`D:\DLSSNR-Lab\geom1088-20260930\`，未装游戏）

- `dlss5-amd.addon64` **aa74b20b**（`aa74b20bc5b4da0d9e461695cc159d01c5b21ce3ac8e9650f4e1fcee4340866e`）：HEAD＋本补丁的 add-on（HEAD 源码不含工作区里别人未提交的 src 改动）。
- `rt-new\LmxxfNrRuntime.dll` **2d561e2d**（`2d561e2d6c3eccf197c0b61d65b34782eb0c37e08c4b418fa9313d9489f5775b`）；`rt-old` 为 HEAD 基线 20630dc7。
- benchmark-base/P/Proll、`flat-A`（剑星现装 31 模块）、回归与 geom 输出。

复现：`Development/HIP/experiments/geom-1088/`（build.sh → setup.ps1 → full.ps1 → geom.ps1 → rtc.ps1）。

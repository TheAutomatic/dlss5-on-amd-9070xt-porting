# 自由分辨率开关 `DLSS5_NETWORK_FREE_RES`（2026-10-02，光派单，子代理，未装机）

起因：TheAutomatic 要一个开关，让网络按游戏实际分辨率跑，不再吸附到 720/900/1080 三档。**默认 0，0 时输出逐位不变、速度中性**（19 组 SAME + ABBA；RE9 runtime 900/1080 SAME）。开 1：任意 320×320～4K 处理面都能跑，fast 路径与通用慢路径逐位一致，1440p/4K 对 NVIDIA 从 35.9/33.3 dB 提到 46.4/48.5 dB。

## 1. 原版几何规则（评估）

- **NVIDIA 宿主**（`0x18003c580`，见 `fma-vs-nvidia-20260928/geometry-audit.md`）：每轴补到 `1<<count` 的倍数（count = 图里尺寸下降的次数），至少 320；两轴都是 4×step 倍数时再给第二轴加一个 step。
- **mochizuki 从 310.8 复原的 plan walk**（`nr_native_plan.cpp`，本目录 `walk.cpp` 编出来跑过）：count=6，即 step 64；额外一步加在**宽**上；ViT 网格 = 每轴 /64 向上取 4；更深各级也向上取 4（如 1472/32=46→48）。
- **两份证据有矛盾**：游戏内抓到的 1080 调用是 1920×1152（step 128），walk 给 1088。用 NVIDIA NGX 输出（mochizuki 公开的单帧，Style 0，全 71 块）实测：

| 输入 | 候选处理尺寸 | 对 NVIDIA PSNR（全块 / 发布跳块） |
|---|---|---|
| 1920×1080 | **1920×1152**（抓包） | **47.43 / 44.26** |
| | 1920×1088（walk） | 45.76 / 43.40 |
| 2560×1440 | **2560×1472**（walk） | **46.41 / 43.62** |
| | 2688×1536（step128+宽） | 43.78 / 42.23 |
| | 2624×1536 | 43.03 / 41.63 |
| | 2560×1664（step128+高） | 42.44 / 41.11 |
| | 2560×1600 | 41.91 / 40.72 |
| | 2560×1536（不加那一步） | **30.82 / 30.15** |
| 3840×2160 | 3840×2176（两种规则相同） | 48.52 / 44.61 |
| 参照：现在的档位（缩到 1080 档） | 1440 / 4K | 35.94 / 33.29 |

  结论：1080 是 1152，1440 是 1472；单一 step 解释不了，原因没查清（count 可能和尺寸有关）。**能不能和原版逐位一致：不能**，1080 同几何本来也只有 47 dB（数值路线不同）；1440 我们比 mochizuki（47.99）低 1.6 dB，差在他按 NVIDIA 把深层 46 行补成 48，我们跑的是不补的 46 行（和 900 档、1088 档一样）。
- **「两轴都是 256 倍数」不是装饰**：不加那一步时 ViT 网格没有零 token，整幅偏色（1440 只有 30 dB）。**我们现有的 720 档 1280×768 正好是这个情况**：同一 1280×720 输入，1280×768 对 1344×768 / 1280×832 都只有 28 dB（Style 0；后两者之间 42.5 dB），均值偏 +1.3～1.9 级。没有 NVIDIA 720 参考，但很可能 720 档本身偏离原版。**只记录，没改 720 档**，请 Zero 定。

**采用的规则**（`NativeNetworkGeometry::Free`）：walk（step 64，宽加一步），唯一例外：结果是 1088 行时取 1152（抓包 + 实测都支持；也让 1920×1080 输入与 1080 档逐位一致）。输入放左上角，右侧列由编码 shader 镜像（`NATIVE_CODEC_FIT_MIRROR`，`2*edge-2-x`），下方行沿用 RGB 输入 pass 的镜像。ViT 网格 pad4；处理尺寸正好是档位（1600×960/1024）时沿用档位网格（25×16），所以 1600×900 输入也与 900 档逐位一致。

## 2. 写死三档的地方（清单）

| 位置 | 内容 | 处理 |
|---|---|---|
| `src/native_network_geometry.h` FromHeight / VitTokens | 三档尺寸、240/400/640 | 加 `vit_w/vit_h` 与 `Free()`；三档不动 |
| `src/native_input_geometry.h:22` | 网络视口白名单（throw） | 新增 free 重载：左上角 1:1 放置 |
| `Supported()` 调用（codec、readback、pre_upscale、RE9） | 1920×1080 像素预算 | 改用 `NativeAdmitLargeInput()`（= FIT_LARGE 或 FREE_RES） |
| `shaders/native_game_rgb_input.hlsl:12` | 行补到 128 倍数 | free 时宿主传 `NATIVE_RGB_PROCESSING_HEIGHT` |
| `shaders/native_codec_encode.hlsl` | FIT 时视口外填黑 | free 时 `NATIVE_CODEC_FIT_MIRROR` |
| `native_temporal_coordinates/sample.h`、history guard、output smooth | 1D dispatch ≤65535 组（≤4.19M 像素） | 超出时 `NATIVE_WIDE_ROW` 2D dispatch |
| `hip_reference_network.h` 构造白名单 | 6 个固定几何 | 加 `FreeGeometry`（64 倍数、非档位） |
| 同上 head `Down` / `GatherFoldOk` / vw,vh / AE stride | `60×36→32×20`、`W==1920?32:W/64`、+1 行补 16 | free 时 pad4 |
| 同上 ViT `n>640` throw（两处） | 640 token 上限 | free 时放开（注意力核 `MAXT` 实际没用，循环按 tokens） |
| 同上 PDL | 每槽 16384 个计数器 = 4.19M 处理像素 | free 且超出时关 PDL（否则计数器越界） |
| 同上 `SwinRunCompatible`、C256 wave-owned 只认 1920 | 900/1080 专用快路径 | 不动：free 尺寸走现有分 PDL 路径 |
| `src/native_post70.h` 等 D3D(HLSL) 网络 | 白名单 | 不动：free 只支持 HIP 后端 |
| `shaders/native_codec_decode.hlsl:30` 非 FIT 行距 1920 | 只在未适配（1920×1080）时用 | 无需改 |
| RE9 runtime flags 白名单 | — | 加 `DLSS5_NETWORK_FREE_RES` |

已经参数化（不用改）：编码器各级 `W/2..W/32`、窗口数、persistent swin（按尺寸门控）、HIP 各核的 tokens/width/height 参数、codec FIT 路径、时序坐标镜像。

## 3. 验证（lab `D:\DLSSNR-Lab\hip-backend\free-res-20261002`，现装 31 模块 flat-N，GPU 锁 + 看门狗）

**默认（开关 0）** —— `final.log`（最终二进制 benchmark-F 41F93A61，runtime 77A35681）
- add-on 路径：**19 组 SAME**；ABBA 900 −0.009/+0.023/−0.014，1080 −0.004/−0.048/+0.025；合并 avg 900 7.140→7.140、1080 9.864→9.855，p99 7.400→7.410、10.183→10.151。中性。（第一版二进制 `go-run1.log` 也 19 SAME。）
- RE9 runtime：rt_bench 900 **b2980ada** / 1080 **758674a8**，旧 runtime、新 runtime、新 runtime+新 shader 三者相同；smoke 0。rt ABBA 900 +0.006/−0.001/+0.011，1080 +0.014/+0.020/+0.008（第一轮 +0.007/−0.028/+0.008、+0.008/+0.001/−0.027）——噪声量级，但最终一轮偏正，装机时再看。

**开关 1**（bench_ngx：完整 NativeGameFrame，单帧 reset，CODEC_SRGB=1）
- 8 个尺寸都跑通（1280×720、1366×768、1600×900、1706×960、1920×1080、2560×1440、3440×1440、3840×2160），无 NaN；重跑哈希相同；**关掉 PDL/wave-owned/C512_M32/VIT_PROJ_N64/VIT_STREAM 的通用路径与 fast 路径逐位相同**（8/8；这些开关确实生效：1080 帧时 16.8 vs 10.0ms）。1920×1080 = 1080 档、1600×900 = 900 档（哈希相同）。RE9 runtime：1707×961、1920×1080（= 1080 档）、2560×1440、3440×1440 跑通且可重复。
- 画面：3440×1440 目视正常、边角无异常。对档位输出：1706×960 36.7 dB、2560×1440 33.1、4K 31.5；1280×720 / 1366×768 约 27 dB（对面是 720 档，见 §1）；3440×1440 26.8 dB，档位那边因为信箱黑边整体偏暗 8.5 级（档位对输入 24.2 dB，free 27.4）。
- 速度（bench 整帧中位数，含编解码，40 帧）：

| 输入 | free 处理尺寸 | free ms | 档位 ms |
|---|---|---:|---:|
| 1280×720 | 1344×768 | 5.89 | 5.65（1280×768） |
| 1366×768 | 1408×768 | 6.17 | 5.73（缩到 720 档） |
| 1600×900 | 1600×960 | 8.02 | 8.32（同一档） |
| 1706×960 | 1728×960 | 8.80 | 8.34（缩到 900 档） |
| 1920×1080 | 1920×1152 | 11.16 | 11.22（同一档） |
| 2560×1440 | 2560×1472 | 18.55 | 11.73 |
| 3440×1440 | 3456×1472（无 PDL） | 24.72 | 12.22 |
| 3840×2160 | 3840×2176（无 PDL） | 39.69 | 12.95 |

  基本按处理像素线性（1440 1.7×、21:9 2.3×、4K 3.6× 于 1080 档）。free 尺寸走不到 SwinRun/C256 wave-owned 快路径，>4.19M 像素再丢 PDL；按已知数这几项合计约几个百分点，没单独量。

## 4. 不支持 / 注意
- 任一边 <320、处理面 >3840×2176 像素（或单边 >8192）：不进 free，回到档位（+FIT_LARGE）。
- 只支持 HIP 后端（发布包都是）。
- 时序：padding 列在时序历史里是网络输出；运动向量按网络面像素归一，与信箱适配同一套逻辑，没对 NVIDIA 做时序对比（没有公开序列）。
- 诊断：`DLSS5_NETWORK_FREE_PAD=WxH`（强制处理尺寸，64 倍数）、`DLSS5_NETWORK_FREE_EXTRA=w|h|0`。

## 文件
`Development/HIP/experiments/free-res/`：`build.sh`（Linux 交叉编）、`setup.ps1`、`ngx.ps1`/`smoke.ps1`/`check.ps1`/`speed.ps1`/`nvidia.ps1`/`geom{720,1080,1440}.ps1`/`final.ps1`/`go.ps1`/`rt.ps1`/`guard.sh`、`bench_ngx.cpp`、`walk.cpp`（mochizuki plan walk 计算器，需他的仓库）。PSNR 用 `results/fidelity-ngx-20260930/psnr.py`。

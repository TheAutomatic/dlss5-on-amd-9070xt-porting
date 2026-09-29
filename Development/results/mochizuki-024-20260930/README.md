# mochizuki 0.0.2.4 静态对照（09-30，未占 GPU）

源：github.com/mochizuki0323/DLSSNR-AMD，tag v0.0.2.2=228d3a6，v0.0.2.3=729a05d，v0.0.2.4=743326d。本地 clone 在 scratchpad，不入仓。

## 1. 性能：0.0.2.2→0.0.2.4 没动网络
- 两个提交（48 文件 +2553）全是产品侧：`runtime_prep.comp`（opt-in 预处理/自动曝光，默认关，关时不录制）、ini 热重载、DXGI 颜色格式兜底、OptiScaler 补丁、ngx-verification 文档。`build_network.py` 只把 runtime_prep 加进列表；卷积/GEMM/ViT shader 零改动。
- 自报耗时仍是 **v0.0.2.2 测的离线数**（RX 9070 XT，网络本身）：Linux 1080p 5.60 / 1440p 9.89 / 4K 22.32 ms；Windows 1080p 7.79 / 4K 28.9 ms（未进游戏验证）。游戏内只报整帧 fps（如 4K 输出 27～30fps、1080 输出 54～68fps）。
- **口径不同**：他 1080 档工作尺寸 1920×1088（`nr_pe_session.cpp:413`、`occ_pad.glsl`），我们按 NVIDIA 原版调用参数 1152 行；Linux=Mesa RADV+ACO(Vulkan GLSL)，我们=Windows 驱动 HIP。5.60 vs 我们 1080 约 10.8ms 不能直接比，Windows 他 7.79 也是 1088 行。要比须同机同尺寸实测（上轮剑星实测他 Windows 与我们 0.36 打平）。

## 2. 数值路线
- ARCHITECTURE 自述"FP8 处同 NVIDIA 用 FP8，其余 FP16/FP32"；shader 用 `inversesqrt`（17 处）与 `1.0/x`，即近似 rsqrt/rcp 由编译器决定，非 NVIDIA MUFU 同序；归约/累加顺序与 NVIDIA 不同（上轮已看 ViT 分母 packed-half 树）。
- 几何：1088 行（相对原版少 64 行，有损），没发现跳层。
- Windows 与 Linux 仍自报差 48.6dB（AMD Windows 编译器舍入不同）；ngx-verification 只测 Linux 版。
- **他的 45.6/48.0/49.1dB 口径**：8-bit sRGB 最终图、单帧无 history、Reset、常量深度零运动、一张 Tomb Raider 图 Lanczos 缩放；RTX 5090 + Wine 跑原版 nvngx_dlssnr.dll 310.8。我们的口径（`results/float-fma-20260928`）是 raw float 网络输出 RMSE≈0.00804（1080 可见行，71 块，post_shift=3，对原 CUBIN oracle），不经 8-bit 量化、不含前后处理。两者**不能直接比**；要比须把我们输出过同一套 8-bit 管线算 PSNR。
- 他 1080 最差且整体偏亮 +0.4/255，1440/4K 更好——和 1088 行裁剪/缩放边界、或前处理差异一致（推测，未验证）。

## 3. ngx-verification 值得借鉴
方法干净：不提取、不重放，原 dll 走 NGX 公共 API（Init_Ext→CreateFeature→EvaluateFeature，每帧 Reset），同输入同参数，8-bit 输出比 PSNR/SSIM/edit 相关/1-step 像素比例；原版两跑字节相同作为噪声底。
**我们可以在 3080 游戏本（Windows 原生 D3D12，不需 Wine）做同样的端到端对照**，输入直接用他仓库的 `docs/ngx-verification/inputs/*.png`、同默认参数，还能直接和他的 `outputs/*_nvidia.png`（5090）交叉核对 Ampere/Blackwell 一致性。这样就有了三家同口径的公开数字，也是整网（含前后处理）对原版的检验，我们现有的是网络 raw 对 CUBIN。注意 dll 版本/NGX core 要与他一致（310.8；他说旧 core 报 0xBAD0000C）。

## 4. 可抄的
- **逐位提速：本版无新网络改动，无可抄**。上一版路线已交负账（I/P/S/V/F/O/G/H，`mochizuki-022-20260928`）。1088 行是有损，不追。
- 产品侧（不影响网络逐位）：①DXGI 颜色格式兜底（R9G9B9E5、B8G8R8X8、R32G32B32 typeless 等，按 vkd3d VkFormat 映射，开关 `NR_FORMAT_FALLBACK=0` 可关），我们如遇未知格式直通可参照其表；②ini 每秒热重载+热键；③预处理/自动曝光（改变网络输入，属有损画质功能，只能做成 opt-in，默认关时须逐位不变）。

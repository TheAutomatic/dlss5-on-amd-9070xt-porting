# Yimo / 伊莫：单帧 NR 输入敏感性的最小复现

两张真实模型入口帧（8678、8680），不是截图转换，也不是合成输入。来自同一次用户报告闪烁的游玩录制。它们并非全屏相同：存在运动、jitter 和采样变化。本例复现的是微小/局部输入变化被网络放大，以及输入相对稳定区域的输出波动；不声称两张快照就证明整段视频的全部闪烁。

## 包含什么

- `inputs/`：2 个 RGBA16F 模型入口，1920×1080、HWC、小端。
- `expected/`：同输入的 AMD exact-reference 输出 RGB32F，1920×1080、HWC。**这是移植参考输出，不是原始 CUDA oracle。**
- `replay.exe`、`modules/`：Windows x64 / gfx1201（9070 XT）的可运行复现；静态链接 MSVC runtime，使用系统 AMD HIP 驱动。
- `src/`、`build.cmd`：重放器和实际使用的头文件、4 模块对应的 HIP 源；`LICENSE.lmxxf` 保留许可。内核 recipe 为原参考模块，编译定义 `HIP_ISA_HALF=1`；C32 模块按 c32_reference.hip + prefix_reference.hip 拼接。没有实验性高精度内核。
- `manifest.json`、`SHA256SUMS`：输入/权重/噪声表/包内文件校验。`verify.py`：无游戏运行依赖的指标复算（Python 3 + NumPy）。

## 9070 XT 上运行

使用现有 `native-game-tiled-assets`（模型和 noise.f32 不重复分发；manifest 有 64 个文件的 SHA256）。解压后在包根目录运行：

```powershell
python verify.py --assets "D:\path\native-game-tiled-assets"
.\replay.exe "D:\path\native-game-tiled-assets"
python verify.py --outputs output
```

双 GPU 机器可在 replay.exe 的最后指定 HIP device index，例如 `... 1`。预编译模块只适用于 gfx1201。重放器不读取宿主 ini、不需安装游戏、不调用 codec，不依赖原报告机器路径。每个输入运行两次，逐位检查确定性，再与包内 expected 逐位比较；不同则退出非零并保留输出。参考链较慢，请等待每帧输出。

重编译重放器：在 x64 MSVC Developer Command Prompt 中运行 `build.cmd`。CUDA/DGX 上不要运行 Windows/gfx1201 二进制；按下面的输入契约调用原始模型。

## 原始 CUDA 对照所需契约

输入**已经编码**，不要翻图、再次 sRGB/线性转换、曝光或 tone map。行顺序是采集时 GPU 资源顺序（视觉上可能上下颠倒）；不要按截图方向修正。无水平 padding；处理高 1152，y>=1080 的源行是 `2158-y`。seed=1；post_shift=3；完整 0–70 层，不跳 42/43/46；History/adaptive reuse 关闭；原 noise.f32 入口，不使用 fast-prefix 近似。

请对两张输入各独立重复两次，返回最终网络 RGB32F（前1080行，decode/clamp/FP16 存储前），并说明实际内核/模型/参数及两次结果是否逐位一致。若原始接口字段不等价请指出。若同一轮方便，附 block30、head/gather 前和 block38 的激活，注明形状/布局/算子位置，便于结果不同后继续定位。不要以另一版 HIP/HLSL reference 代替独立原 CUDA 结果。

## 定量复现与已有排查

基线固定 upstream pin `54e14de503431cd4536f8a7151b022af232178a9` 的模型/参考模块；宿主来自 1.9.6.3 test 系列。附带头文件有产品诊断/生命周期补丁，但本例未启用诊断宏、快速路径或复用；源码均随包提供，不依赖产品仓库。

逐像素稳定定义：线性 RGB 每通道变化 < `0.003 + 0.03*abs(old)`。32×32 块超过90%像素稳定且原图均值>0.02时纳入。统计 `(new_output-old_output)-(new_input-old_input)` 的块均值，除以旧输出亮度（最小0.02），取绝对值 p95；顶部1056行组成完整块。

本对有 952569 个稳定像素、194 个稳定块。附带 AMD reference p95=14.943196%；稳定像素残差 MAE=0.005807238。不是全屏统一曝光变化，也不是逐像素不动的证明。

同一对 test20 快速候选（C32 attention probability FP16）p95=23.315485%；全激活高精度参考实验仍约13.24%；对齐 jitter 未跨片段稳定改善。相同输入重复推理逐位一致。整个 test21 的16个输入也在原噪声表/完整层 reference 上复算，仍有波动。

另外，用此对输入做局部替换诊断，保持 ROI 周围320×320输入不变、仅更改外部时，ROI 输出仍变化（test20 -2.051%、高精度 -2.435%）。这是非局部影响证据，不证明某个 ViT 算子错误。

HDR 已排除；关闭复用不足以修复；不以降低 Detail strength、History 或输出时间平滑作为已验证根因修复。鸣潮也有用户报告，但缺独立同输入证据，**不宣称两款游戏同源**。

希望确认：原始 CUDA 是否也呈现同类响应；若原始 CUDA 稳定，定位参考/移植契约或算术差异；若原始 CUDA 同样敏感，再讨论模型输入/时序契约。当前没有已证实的唯一根因或完整修复。

Archive SHA256: bfa72f1ed94ca3bd3edb46beb68e50a844439875e89b1c3ea188c15c04cfb2b3

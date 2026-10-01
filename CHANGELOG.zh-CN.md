# 更新日志

[English](CHANGELOG.md) · README 里的更新记录表是一行一版的摘要；这里按版本展开：改了什么、效果、开关、是否逐位、对应的实验目录。版本从旧到新，新版本加在最后。

说明：
- 「逐位」指快速链输出与上一版一位都不差（EXACT 与 AE 都算）。0.01 之后精确参考链冻结当裁判，快速链对它约 42 dB PSNR。
- 「离线」是只跑网络的测试台（1000 帧弃前 200 取均值），「900 档 / 1080 档」是网络处理 1600×960 / 1920×1152。游戏内帧率除注明外为《剑星》、RX 9070 XT。
- 没测过的数字不写。实验记录在 `Development/results/<目录>/`，过程在 `Development/DevHistory.md`。

## 早期版本（0.01～0.23）

这一段的细节就是 README 更新记录表对应行，这里只列要点。

| 版本 | 日期 | 要点 |
|---|---|---|
| 0.01 | 09-08 | 精确移植终点：71 块全走 wave 矩阵核，15 帧与原版逐位一致；测试台 186 ms，约 5 fps |
| 0.02 | 09-08 | 快速链开始（精确链冻结当裁判）：FP32 硬件累加、E4M3 操作数；接上时序；112 ms |
| 0.03 | 09-08 | 硬件 f16/E4M3 转换、QKV+归一化合核等；62.7 ms，约 15 fps |
| 0.04 | 09-09 | 延迟提交环、命令列合批、噪声前缀 ALU 生成；23～25 fps |
| 0.05 | 09-09 | 输出侧时间平滑、ViT 注意力 FP8；24～25 fps |
| 0.06 | 09-09 | 仓库重整、GPU 探针默认关、pre 块输出 E4M3；27～28 fps |
| （0.07） | 09-09 | 跳过三块（有损，40.7 dB）、显存 6.8→3.75 GB；29 fps |
| 0.08 | 09-10 | 一批逐位的布局/直读优化；《浪人崛起》XeSS 路径；测试台 24.4 ms，36～37 fps |
| 0.09 | 09-11 | 升采样投影 f16 光栅（逐位，−0.2 ms）；Magpie 版可用于任意游戏（约 30 fps） |
| 0.10 | 09-11 | 黑块根因修复：E4M3 转换前夹到 ±448（`DLSS5_BUILD_C32_SAT_CAST`） |
| 0.11 | 09-11 | 接管时间 20～30 秒 → 约 3.5 秒（预读权重、批量常驻、shader 磁盘缓存） |
| 0.12 | 09-12 | 屏幕提示（分辨率不对/初始化中/失败）；`DLSS5_NOTICE` |
| 0.13 | 09-12 | `DLSS5_SHOW_FPS`；按输出状态接管 |
| （0.14） | 09-12 | Magpie 整包：FPS 三秒刷新、清理 |
| 0.15 · [包](https://pan.quark.cn/s/1601ca8f80ae) | 09-13 | 窗口 ≤1920×1080 按比例适配（`DLSS5_FIT_INPUT=1`）；另有 [0.15-900P](https://pan.quark.cn/s/a5339e4c8549) |
| 0.20 · [包](https://pan.quark.cn/s/3c8b5329353c) | 09-17 | **HIP 后端**：COMGR 编 gfx1201 内核，与 DX12 链逐位一致；900p 约 15.5 ms、游戏内 900p 52 fps |
| 0.21 · [包](https://pan.quark.cn/s/85a507a744bd) | 09-17 | `DLSS5_NETWORK_HEIGHT=auto` 自动选档；与 0.20 逐位 |
| 0.22 · [包](https://pan.quark.cn/s/03f9995d0551) | 09-17 | 900 档补边 1024→960 行（−0.9 ms）；**输出变化**（对 0.21 约 31.5 dB），`900w` 可回旧布局 |
| 0.23 · [Magpie](https://pan.quark.cn/s/548e52cc4f49) · [OptiScaler](https://pan.quark.cn/s/8b5a402012a2) | 09-18 | 多 GPU/核显机器按适配器名选 HIP 设备；与 0.22 逐位 |

## 0.24（09-19）

下载：[OptiScaler](https://pan.quark.cn/s/1f32ffbd2e96)（HIP）

- **改了什么**：前置超分路线——游戏低分辨率颜色 → DLSS5 → OptiScaler 的 FSR 3.x/4 → 最终输出，同队列异步提交。只改本项目插件；OptiScaler 本体、权重、内核不变。
- **效果**：《剑星》2560×1440、FSR 质量档（输入 1707×961）约 34～35 fps。
- **行为变化**：DLSS5 历史暂时每帧重置（FSR 时序保留）；网络输入仍须 ≤1920×1080。
- **逐位**：网络输出与 0.23 相同。

## 0.24.1（09-19）

下载：[OptiScaler](https://pan.quark.cn/s/4f73a54d0ff9)（HIP）

- **改了什么**：配置/资产路径查找——DLL 被加载到 `_storage_` 等子目录、旁边没有 `DLSS5-AMD` 时，继续到游戏 EXE 旁查找，避免误读开发目录的旧配置。
- **逐位**：内核与权重不变。
- 不解决《生化危机 9》同一命令列表内的前置接入限制。

## 0.24.2（09-19）

下载：[OptiScaler](https://pan.quark.cn/s/f74aaa5c7f9a)（HIP）

- **改了什么**：插件在没有前置任务时不再每次绘制都查配置、锁任务表；减少日志计数争用；F6 关闭时直接旁路前置捕获和颜色复制。同日重打完整包，补上 FPS/状态显示开关。
- **效果**：《剑星》主城约 49 fps（此前约 31 fps，CPU 开销）。
- **逐位**：内核与权重不变。

## 0.25（09-19）

下载：[Magpie](https://pan.quark.cn/s/09630ed99606) · [OptiScaler](https://pan.quark.cn/s/636691131c5f)（HIP）

- **改了什么**：C32/多头注意力复用指数计算、简化倒数；中间特征和解码输出以 FP8 字节传递；解码完整分组走快速路径。修复 900 档尾部漏写、中文路径加载失败。**新增 gfx1200（9060/XT）内核**，与 gfx1201 按设备自动选择。
- **效果**：Magpie 1080P 仅 DLSS5 约 37 fps，与之前基本持平。
- 9060/XT 当时待实机反馈。

## 0.26（09-19）

下载：[Magpie](https://pan.quark.cn/s/7ce2ca11db43) · [OptiScaler](https://pan.quark.cn/s/c880a70f0824)（HIP）

- **改了什么**：FFN 直接读 FP8 字节片段（省入口共享缓冲暂存和两道同步）；C256 权重初始化时预排成连续矩阵片段。补齐漏打包的 R11G11B10 解码 shader（修复《匹诺曹的谎言》低效果品质黑屏）；增加 shader 编译/绑定校验。
- **校验**：包内文件及 44 种 shader 组合校验通过。

## 0.26.1（09-20）

下载：[OptiScaler-REFramework](https://pan.quark.cn/s/624c87a6aa11)（HIP，RE9 专用）

- **改了什么**：RE9 这类特殊接入的后置 HIP 路线——R10G10B10A2/FP16 转换、FSR 后处理、固定 900P 计算、1080P SDR 输出保护；状态/分辨率/Present 帧率与 F7 信息开关。集成 REFramework、OptiScaler、ReShade、完整模型与双架构内核，沿用 0.26 优化。
- 仅《生化危机 9》实测，普通游戏用通用包。

## 0.27（09-20）

下载：[Magpie](https://pan.quark.cn/s/ec3a3282aa76) · [OptiScaler](https://pan.quark.cn/s/004278159ed8) · [OptiScaler-REFramework](https://pan.quark.cn/s/010683548f68)（HIP）

- **改了什么**：精确流式 ViT 注意力，减少中间存储与重复读取，保持原计算与舍入。可选 R3 自适应复用（变化检测、静止延长缓存、融合提交），**默认关**。
- **逐位**：流式 ViT 与原计算一致；自适应复用是可选的有损开关。
- 三包各 44 个 shader 变体及 ZIP 逐文件校验通过；不含 INT4/剪枝。

## 0.28（09-22）

下载：[Magpie](https://pan.quark.cn/s/11547f398eb4) · [OptiScaler](https://pan.quark.cn/s/f7f423b0ea3a)（HIP）

- **改了什么**：六项无损内核优化——RGB 共用读取、C128/C256 零填充跳过、ViT 展开/投影与解码投影固定尺寸。
- **效果**：《剑星》实玩效果/帧率基本不变。
- RE9 的 0.28 下载已撤下，改用 0.28.1。

## 0.28.1（09-22）

下载：[OptiScaler-REFramework](https://pan.quark.cn/s/1375693a0d21)（HIP，RE9 专用）

- **改了什么**：真实输入超限时在 HIP 初始化前拒绝并保留原始超分；初始化失败安全回滚，改回有效尺寸可恢复；保护未退休帧。宿主与 runtime 需配套更新；源码与 TheAutomatic 署名随包。
- **校验**：10 组 / 12 提交帧回归与用户初步实玩通过。

## 0.29（09-23）

下载：[Magpie](https://pan.quark.cn/s/fe1b6af36cad) · [OptiScaler](https://pan.quark.cn/s/209e04e7acaf) · [OptiScaler-REFramework](https://pan.quark.cn/s/505d38a63a85)（HIP）· [Google Drive 镜像](https://drive.google.com/drive/folders/1VPsX33sLTxBG4J8kJ_IzBDlkbBTCc5Eo?usp=sharing)

- **改了什么**：
  - 超过 1920×1080 的输入不再拒绝：缩到 1080 档跑网络，再按原版 codec 方式还原到原分辨率（`DLSS5_FIT_LARGE=1`，issue #6）。
  - 自 0.28 以来六项逐位优化：栅栏作用域、C32 折叠 FFN、字节链 + 向量化输入、注意力寄存器化、in16 别名、FFN 尾段转置。
- **效果**：内核约 −7%；《剑星》900P 约 60 fps、2K Native AA 44 fps；RE9 Native AA 实测可用（超宽屏未实机）。
- **新开关**：`DLSS5_FIT_LARGE=1`（模板默认开）。
- **逐位**：内核优化逐位；FIT_LARGE 是新的输入路径。
- RE9：宿主不变、runtime 更新。

## 0.30（09-25）

下载：[夸克](https://pan.quark.cn/s/80a735ab9f88) · [Google Drive 镜像](https://drive.google.com/drive/folders/1pKZpLosgJXxUOZTMg_m0sbCipX9Q3WYo?usp=sharing)（三个包）

- **改了什么**：
  - 链上 launch 任意序 + tile 旗子（土法 programmatic dependent launch，`DLSS5_HIP_PDL=1`），C64～C256 链。
  - FFN 全行写。
  - 《赛博朋克 2077》零配置：常规包 `OptiScaler.ini` 带 `[Inputs] EnableFfxInputs=false`；`DLSS5_PRE_UPSCALE_ASYNC=auto`（2077 同步：瞬态别名颜色缓冲）；`DLSS5_STRENGTH=auto`（2077 只转亮度）。
  - 修复切档位/分辨率后神经处理消失（FSR 上下文钉死）。
- **效果**：PDL 900P 约 −1.6%、1080P −0.6%；FFN 全行写 −0.6%。《剑星》900P→2K 60～61、1080P→2K 47～48；2077 低画质平衡 51～52、质量 41。
- **新开关**：`DLSS5_HIP_PDL=1`、`DLSS5_PRE_UPSCALE_ASYNC=auto`、`DLSS5_STRENGTH=auto`（模板默认）。
- **逐位**：PDL 与 FFN 全行写逐位。
- **实验目录**：`results/pdl-chain-20260925`。
- RE9 包：同一组核，宿主/runtime 与 0.29 相同。

## 0.31（09-26）

下载：[夸克](https://pan.quark.cn/s/e76b8611e3cc) · [Google Drive 镜像](https://drive.google.com/drive/folders/1xtBe_XhgF9eqBlrlIQMgWcEkzm0UKHIZ?usp=sharing)（三个包）

- **改了什么**：
  - 档位选择：输入两轴都不超过某档 110% 时往下缩进该档（2K 质量 1707×961 → 900 档，原先放大进 1080 档）。
  - 一头一 wave 核（C32/C64/C128 整块 + C256 注意力，`DLSS5_HIP_WAVE_OWNED=1`）。
  - C512 QKV/mix 32 token（`DLSS5_HIP_C512_M32=1`）。
  - ViT 投影 64 列（`DLSS5_HIP_VIT_PROJ_N64=1`）。
  - 常规包默认 `DLSS5_VIT_ADAPTIVE=1`（自适应复用，静止 +3 帧，运动自动失效）。
  - 五个新模块（c32-wave1、c64-wave2、c512-m32-mh、c512-m32-deep、vit-wide-deep），每架构 29 个模块。
- **效果**：一头一 wave 整网约 −6%；C512 M32 约 −1.3%；ViT N64 1080 约 −1.8%。《剑星》主菜单 2K 质量 57、2K Native AA 43～44。
- **逐位**：三组内核改动逐位；档位选择改变 2K 质量档的网络档（行为变化）；VIT_ADAPTIVE 为有损复用（可关）。
- **实验目录**：`results/c64-wave2-20260926`、`wave-owned-*`、`c512-ffn-20260926`、`m32-sweep-20260926`。
- RE9 包：宿主/runtime 与 0.30 相同，新核随包不启用。

## 0.32（09-26）

下载：[夸克](https://pan.quark.cn/s/b805e071405c) · [Gofile 镜像](https://gofile.io/d/CZ67LYIc)（三个包）

- **改了什么**：
  - 显存池：HIP 导入的 D3D12 共享缓冲区驱动不归还，改为按档位复用（切 40 次 +3 GB → 平台）。
  - C32 宽读（向量输入读取）。
  - RE9 runtime 读 flags（`DLSS5_HIP_*` / `SKIP_BLOCKS` / `FIT_LARGE` / `NETWORK_HEIGHT`），默认开 0.31 新核，兼容老宿主两参数 `EnqueueHip`；合入 PR #9。
- **效果**：C32 宽读 −0.8% / −0.9%；离线 900 档 10.74 ms、1080 档 15.01 ms；RE9 中画质 2K 高质量 54、原生 AA 38。
- **逐位**：C32 宽读逐位。
- **实验目录**：`results/vram-leak-20260926`、`c32-wave-phase-20260926`、`re9-runtime-flags-20260926`。

## 0.33（09-27）

下载：[夸克](https://pan.quark.cn/s/6bb64e46ab67) · [Gofile 镜像](https://gofile.io/d/8yAjJX1b)（三个包）

- **改了什么**：
  - FP8 打包：c32-wave1 的 `CW_PACK8`、c64-wave2 的 `W2_PACK8`——一条 `cvt_pk` 转两个值写进片段字。
  - 插件：前置状态行显示 AE/EXACT；F7 开关屏幕文字；共享的环境选项解析。
- **效果**：离线 900 档 10.74→9.80 ms、1080 档 15.01→13.64 ms（约 −9%）。《剑星》1080P 原生 AA EXACT 主菜单 49～50、常见场景 53～54。
- **逐位**：相对 0.32 逐位。
- **实验目录**：`results/c64-block-fused-20260927`、`pack8-20260927`。
- RE9：宿主/runtime 与 0.32 相同（只换模块）。

## 0.34（09-27）

下载：[夸克](https://pan.quark.cn/s/4b572b0a5b81) · [Gofile 镜像](https://gofile.io/d/cfHqVzD1)（三个包）

- **改了什么**：
  - fmed3 clamp（`HIP_FMED3_CLAMP`、C32 `HIP_FP8_SAT_MODE 3`）与 `W2_PACK8 6`（分段 FP16_OVFL + fma(x,y,+0) 打包）；整套模块由 `hip/build-modules.ps1` 按生产配方编出（3 个回退模块从源码重编）。
  - PDL 计数回绕保护；卸载时释放 PDL 缓冲。
  - RE9 宿主 aa3761f2：跟随实际执行拆分列表的队列 + 8 次评估看门狗（《鬼武者》）；runtime ca6d6bdc：切档泄漏 35 MB→0，每次尺寸/档位变化记几何日志；重新生成宿主/runtime 源码包。
- **效果**：《剑星》1080P AA EXACT 主菜单 50～51 / 场景 54；RE9 中画质 2K 高质量 58、原生 AA 41；《鬼武者》2K 质量约 60。
- **逐位**：相对 0.33 逐位。
- **实验目录**：`results/fmed3-ovfl-20260927`、`ovfl-census-20260927`、`c64-hand-asm-20260927`、`pdl-audit-20260927`、`onimusha-presr-20260927`、`re9-runtime-leak-20260927`。

## 0.35（09-27）

下载：[夸克](https://pan.quark.cn/s/83e6172e6c79) · [Gofile 镜像](https://gofile.io/d/NnF4GitT)（三个包）

- **改了什么**：
  - C32 三轮：去重复 FP8 往返（`CW_DIRECT_OUT`、`CW_PREFIX_DIRECT_OUT`）、RTZ/LDS 写向量化（`CW_RTZ_PAIR`）、分段饱和模式（`CW_PACK_MODE_MASK`）、prefix/finish 完整窗口快路径（`CW_PREFIX_FULL_TILE` 等）。
  - ViT 字节流（`DLSS5_HIP_VIT_STREAM=3`，新 `vit-stream` 模块：注意力输出以字节直接喂投影，兼容自适应复用）。
  - 插件 4151123e；每架构 30 个模块；RE9 runtime 432d8ccf（同一开关，宿主 aa3761f2 不变）。
- **效果**：离线 900 档约 9.3 ms、1080 档约 12.75 ms。《剑星》1080P AA EXACT 约 56.7（0.34 为 54）；RE9 中画质 2K 高质量 58～59、原生 AA 42。
- **新开关**：`DLSS5_HIP_VIT_STREAM=3`（模板默认）。
- **逐位**：相对 0.34 全部逐位。
- **实验目录**：`results/c32-aco-20260927`、`c32-round2-20260927`、`c32-round3-20260927`、`vit-bytestream-20260927`。

## 0.36（09-28）

下载：[夸克](https://pan.quark.cn/s/e5afdaca0769) · [Gofile 镜像](https://gofile.io/d/Z1hWdjcB)（三个包）

- **汇总**：插件 d2290ad7；每架构 30 个模块；RE9 runtime 7ce2bc21（宿主 aa3761f2 不变）；输入 shader `native_game_rgb_input.hlsl` 5be59a41（匹配输入直写）。
- **累计效果（相对 0.35 发布包，同批两轮 ABBA）**：离线 900 档 9.37 → 8.58 ms（−0.79 ms，−8.5%）、1080 档 12.71 → 11.58 ms（−1.13～−1.14 ms，−8.9%）。1080 档每帧派发 214 → 182。
- **逐位**：**0.36 与 0.35 输出不逐位相同**——float FMA 激活（下面第 4 条）是一次有意的数值变化，对 NVIDIA 原版误差基本持平；0.36 起为新的逐位基准，其余各项在各自那一步都与上一版逐位。
- **新开关**：`DLSS5_DIRECT_IO`（常规/Magpie 模板默认 1，RE9 不写）、`DLSS5_FRAME_STATS=<秒>`（模板默认 0）。
- **改了什么**（按时间）：

1. **C64～C256 深挖**（c64-wave2 配方：字节输入整组读取、RTZ 配对、直接坐标）：离线 900 −0.7%、1080 −0.8%；逐位；只换模块。`results/mh-round1-20260927`、`tier900-20260927`。《剑星》1080P AA EXACT 57.1。
2. **帧时间分布日志** `DLSS5_FRAME_STATS=<秒>`（插件 + RE9 runtime，写 `DLSS5-AMD\logs\frame-stats.txt`，模板默认 0）。`results/frame-stats-20260928`。
3. **ACO 逐段对齐两刀**：删除 C32 激活前多余的 NaN 规范化；C64～C256 softmax 用有界倒数（保留求和顺序与误差修正）。900 −0.82% / −0.65%、1080 −0.75% / −0.74%；逐位。`results/aco-lineup-20260928`。
4. **float FMA 激活（有意的数值变化，09-28 起逐位基准变更）**：C32、C64～C256、ViT/C512 的同类激活乘加收缩为 float FMA（此前为与 HLSL `precise` 对齐的两次舍入；NVIDIA 原版是 half FMA）。900 省 0.110～0.115 ms、1080 省 0.148～0.151 ms（约 1.2%）；对 NVIDIA 原版误差基本持平（单帧 RMSE 0.008038→0.008037）。此后以本版输出为逐位基准。`results/fma-vs-nvidia-20260928`、`float-fma-20260928`。
5. **输入直写 / 输出直交** `DLSS5_DIRECT_IO`（0 原路径、1 输入直写进 HIP 共享缓冲、3 再加 FSR 直接读解码输出）：省一次 35 MB 拷贝与一次回拷；离线 −0.02～0.05 ms；网络输出逐位。时序会话（Magpie）、`DLSS5_OVERLAP` 与非 RGBA16F 格式自动走原路径；RE9 不涉及。`results/zero-copy-io-20260928`。
6. **C256 整块融合**（多组 token 共用一份权重，FFN 权重读取减半，主力核 VGPR 190→154）：1080 −1.67% / −1.63%（约 −0.20 ms），900 保留原路径；每帧派发 1080 档 214→198；逐位。`results/c256-fusion-20260928`。
7. **C512 融合 + C64/C128 权重共用**：C512 每块少一次派发（1080 档 198→185、900 档 214→201），C64/C128 权重读取减半。900 −3.59%（约 −0.33 ms）、1080 −2.55% / −2.63%（约 −0.31 ms）；逐位。离线 1080 档约 11.82 ms、900 档约 8.72 ms。`results/c512-fusion-20260928`。
8. **上采样融进首块**：C64/C128 与 C32 的上采样并入下一级首块，每帧再少 3 次派发（1080 档 185→182、900 档 201→198）；900 −0.17～−0.18 ms、1080 −0.25～−0.26 ms；逐位。ViT 与下采样候选实测不赚，未合。`results/fusion-round3-20260928`（含 `package-036-checklist.md`）。

游戏内（本机，RX 9070 XT，EXACT 静止）：《剑星》1080P 原生 AA 约 57 → 60（已触窗口模式 60 Hz 上限）；2560×1440 原生 AA C512 融合后 52～53、最终 54（此后游戏内对比用这个设置）。


## 0.37（09-29）

下载（三个包）：[夸克](https://pan.quark.cn/s/7dbfdc6425fd) · [Gofile 镜像](https://gofile.io/d/onqeAHST)

- **汇总**：插件 b77bbc3c；每架构 31 个模块（新增 `swin-persistent.hsaco`）；RE9 runtime 2c103f6e（宿主 aa3761f2 不变）；shader 与 0.36 相同（输入 shader 5be59a41）。
- **逐位**：**与 0.36 全部逐位相同**（09-28 float FMA 基准，7 用例 EXACT/AE 168 帧 + 回绕/超时压力帧，每一步都验），没有有损改动。
- **累计效果**：离线网络 900 档约 8.5 → 8.0 ms；每帧派发 900 档 198 → 179、1080 档 182 → 162。《剑星》2560×1440 原生 AA、EXACT 54 → 55～56（本机）。
- **新开关**：`DLSS5_HIP_SWIN_RUN`（C256 持久化；源码默认 0，**三个发布模板都设 1**；RE9 runtime 同样读取；设 0 回到原派发）。
- **包内其他**：常规 OptiScaler 包也带 `ReShade.ini`（`TutorialProgress=4`，去掉 Home 引导遮罩），与 Magpie 包一致；RE9 源码包补上 HIP 配方的 `.inc` 文件。
- **改了什么**（按时间，每一步都对上一步逐位）：

1. **C512 点运算紧凑布局**：FFN/卷积只算有效 tile（1080 档 160 → 135 个 4×4 tile），移位与补边推迟到 attention 读取；attention 窗口与 softmax 不变。900 −0.16～−0.18 ms、1080 −0.23～−0.25 ms（两档各约 −2%）；1080 档派发 182 → 169。`results/deep-layers-20260929`。
2. **逐核地图两刀**：全网 1080 逐核对照（我方 169 / 参考 154 次派发）后，C512 head 池化与投影合成一次派发（head 分组融合），ViT attention 分数排布转置。900 −0.02～−0.04 ms、1080 −0.12～−0.14 ms（1.0～1.2%）；派发 198 → 197 / 169 → 168。`results/kernel-map-20260929`。
3. **C256 跨层持久化**（`DLSS5_HIP_SWIN_RUN=1`）：C256 编码器/解码器各六个内部层走设备就绪队列；约 100 ms 超时即在 GPU 上串行重算该段并停用本实例，坏中间结果不出网。900 −1.90～−1.94%（约 −0.16 ms）、1080 −0.57～−0.61%；派发 197 → 179 / 168 → 162。`results/swin-persistent-20260929`。
4. **ViT attention 新核**：有界正常 half 改用精确硬件转换、概率在寄存器内成对编码、分母/AV 输出转置。640 token 单核约 71 → 38 µs；整网 900 −2.20～−2.28%（约 −0.19 ms）、1080 −1.50～−1.58%（约 −0.17 ms）。`results/vit-attention-20260929`。
5. **ViT QKV 五 wave 共用权重**（W5）：5 个 wave 经 LDS 共用一份权重（8 KB 块双缓冲），读取量约除以 5、wave 数不减；640 token 单核 48.8 → 37.0 µs。整网 900 −0.42～−1.39%、1080 −0.74～−1.07%。新宿主按导出自动探测，旧模块自动回落。`results/vit-qkv-20260929`。

不进包的负账：C128/C64 持久化（未达 0.5% 门槛，`results/swin-persistent-c128-c64-20260929`）、C512 投影权重共用（逐位但变慢，`results/c512-proj-share-20260929`）、`MAKE_RESIDENT` 尖峰（离线未复现，`results/resident-spike-20260929`）。打包清单 `Development/results/package-037/checklist.md`。

## 0.38（09-30）

下载（三个包）：[夸克](https://pan.quark.cn/s/6856d875bbe9) · [Gofile 镜像](https://gofile.io/d/lzsqfUiE)

- **逐位**：**默认设置下与 0.37 全部逐位相同**（09-28 float FMA 基准；7 用例 EXACT/AE 168 帧 + 票号回绕，每一刀都验；打包用的插件与 RE9 runtime 从发布源码重编后，又对现装再验一遍 168 帧 + 回绕，全同）。唯一的有损项是可选开关 `DLSS5_NETWORK_1080_ROWS=1088`，默认不开。
- **效果**（离线整网回放，NativeGameFrame，1000 帧弃 200，单帧 ms）：900 档约 **8.0 → 7.6 ms**，1080 档约 **10.8 → 10.4 ms**（发版模块实测 900 7.551/7.606、1080 10.413/10.458，两轮，`results/hip-roofline-20260930` 第 1 节；逐核地图 `results/kernel-map-v3-20260930`）。每帧派发 900 档 179 → 162、1080 档 162 → 158。游戏内只作正确性验证（《剑星》《鬼武者》不闪不花不崩），帧率读数不作为提升依据。
- **新开关**：
  - `DLSS5_FORMAT_FALLBACK`（三个模板为 1，源码默认 1）：原来不支持的颜色格式——R9G9B9E5、B8G8R8X8、R10G10B10A2、R32G32B32(A32)、R16G16B16A16/R8G8B8A8 SNORM、B5G6R5、B5G5R5A1、B4G4R4A4——常规包 pre-upscale 路线用一个 compute pass（新增 `native_format_convert.hlsl`）转成 RGBA16F 后走原路线；RE9 runtime 走私有 FP16 输出路线。原来支持的格式不经过这张表（逐位）。被拒的格式日志里带格式名。post-upscale / Magpie / XeSS 路线不变。设 0 = 原表。`results/product-fmt-reload-20260930`。
  - `DLSS5_HOT_RELOAD`（常规/Magpie 模板为 1，源码默认 1；RE9 不适用）：游戏运行中改 flags 文件的 `DLSS5_STRENGTH` / `DLSS5_NOTICE` / `DLSS5_SHOW_FPS`，一秒内生效；其余键仍需重启。不改文件即无任何变化。
  - `DLSS5_NETWORK_1080_ROWS`（模板 1152 = NVIDIA 原版几何）：**可选 `1088`，有损、默认不开**——1080 档只算 1088 行，整网约 −0.47 ms（4.4%），对 1152 全帧约 56 dB，底边 32 行略差。`results/geom-1088-20260930`。
  - 宿主内部开关（默认 1，一般不用动）：`HIP_C512_PAD16`、`HIP_C256_FFN_W16`，缺新模块或容量不够自动回退旧路径。
- **改了什么**（按时间，每一步都对上一步逐位；数字是各自当时的 ABBA）：

1. **900 档去 C512 shift_pack**：生产者直接按 16 token 补齐分配（1500 → 1504），C512 块原地读，13 次 `mh_shift_pack` 消失；只改宿主。900 −0.09～−0.11 ms，1080 不变。`results/shift-pack-900-20260930`。
2. **C32 块 4 跳连/下采样存 E4M3 字节**：这两个张量的值本来就是 E4M3 精确值，改存字节后读写降到 1/4。900 −0.05 ms（0.62%）、1080 −0.09 ms（0.82%）。`results/c32-align-20260930`。
3. **C32 对角残差跳过全零半块**（`CW_DIAG_ONLY`）：1080 约 −0.04 ms。`results/small-cuts-20260930`。
4. **I+P+O**：C32 入口/prefix 去 half 往返，C512 mix 与 ViT contract 占用上限。900 −0.03 ms、1080 −0.02～−0.03 ms。`results/small-wins-retest-20260930`。
5. **复合量化**：`FP8(Hrtz(x))` 在 WMMA 字节出口改成整数位掩码，省 f32→f16→f32 往返；2³² 穷举证明。c64-wave2/swin-persistent（`results/composite-quant-20260930`）与 C512 两个出口（`results/composite-quant-c512-20260930`），各 −0.005～−0.03 ms。
6. **C256 FFN 权重 16 字节片段**：一条 16 字节读喂两条 WMMA，k 顺序不变；缺模块/旧宿主自动回退。900 −0.01～−0.03 ms。`results/c256-w16-20260930`。
7. **C32 prefix 下采样 / 块 69 主干存 E4M3 字节**：900 −0.01～−0.02 ms、1080 约 −0.02 ms。`results/prefix-post-20260930`。
8. **三处宽写**：C32 prefix 字节尾（900 −0.04、1080 −0.07 ms，`results/prefix-post-arith-20260930`）、C32 finish 字节尾（900 −0.04、1080 −0.05 ms，`results/tail-vec-20260930`）、C512 t8 字节副本经 LDS 转置宽写（约 −0.01～−0.03 ms，`results/deep-tail-20260930`）。
9. **C512 QKV-attention 去冗余 F + 有界倒数**：AV/QKV 出口的多余钳位删掉，softmax 除法换 rcp + 两步 Newton；两档三轮 −0.02～−0.03 ms。`results/c512-av-f-20260930`。
10. **F/除法清理扫全网**：只收 deep_fast-packed（900 −0.01～−0.04、1080 −0.01～−0.03 ms）。`results/f-sweep-20260930`。

- **包内**：新增 `native_format_convert.hlsl`；三个 flags 模板加上面三个开关；插件与 RE9 runtime 从发布源码重编（tag 0.38）；RE9 宿主不变；RE9 源码包重生。
- 不进包的负账（逐位但不全正，宏默认 0）：D3D→HIP GPU 轮询 `DLSS5_HIP_INPUT_POLL`（`results/handoff-gpu-20260930`）、C512 V 转置（`results/c512-compact-vt-20260930`）、W16 推广 C64/C128（`results/w16-c64-c128-20260930`）、C512 FFN LDS 共用权重（`results/c512-ffn-lds-20260930`）、Infinity Cache 热复用（`results/infinity-cache-20260930`）。打包清单 `Development/results/package-038/checklist.md`。

## 0.39（10-01）

下载（三个包）：夸克（链接待补） · Gofile 镜像（链接待补）

- **逐位**：**默认设置下与 0.38 全部逐位相同**（7 用例 EXACT/AE 168 帧 + AE 决策 + 900/1080 票号回绕，19 组 SAME；每一刀都验，装机版本整体再验一遍）。
- **效果**（离线整网回放，单帧 ms）：900 档约 **7.27 → 6.8 ms**，1080 档约 **10.05 → 9.5 ms**。《剑星》2K 游戏内实测约 **+1.5～2 帧**（55.6～56.1 → 57～58 fps），无闪烁；《鬼武者》正常。
- **改了什么**：一批逐位重排的核——C512 FFN 一个 wave 在寄存器里做完（`C512_FFN_ONE`）、attn-project 残差初始化外提、C32/C64 权重读取外提、解码加宽（`HIP_DEC_WIDE`）、ViT QKV/attention 合并等；每刀各自 ABBA 三轮两档全正才收。过程与数字见 `Development/DevHistory.md`（09-30 晚～10-01）。
- **新开关 `DLSS5_STYLE`**（三个模板都是 `1`，源码默认 1）：NVIDIA NGX 的 Style 控制，`0`/`1`/`2`。之前预处理里写死 Style 1（第 6 个特征 = Style/128），这是原版运行时在《剑星》里实际用的值。现在改成 C32/prefix 模块里的设备常量，宿主加载模块后写入。`0` 是 NVIDIA 默认值、也是他们参考图用的设置（1080p 单帧对 NVIDIA：Style 1 为 24.06 dB，Style 0 为 44.26 dB（发版配方）/ 47.43 dB（完整 71 块））；`2` 是第三种风格。不是恰好 0/1/2 的值回落到 1。改了要重启游戏。默认 `1`：**逐位一致**，GPU 没有多余工作。RE9 包：runtime 目前不从 flags 文件读这个键（模板那行改了不生效），要换风格得设系统环境变量。`results/rebuild-baseline-20261001`。
- **可复现构建**：add-on 和 RE9 runtime 改为固定基址、不写时间戳链接，同一份源码在哪编出来都是同一个文件（之前链接器按输出路径算基址，每次重编所有绝对地址都不同）。本版包里的 add-on 与 RE9 runtime 由发布源码重编逐字节复现；62 个模块按代码段与源码核对。
- 宿主：去掉了一个默认用不上的 fast 档探测（每帧多 0.005～0.02 ms）；查不到的核函数会缓存结果。
- **包内**：三个 flags 模板加 `DLSS5_STYLE=1`；add-on、RE9 runtime、62 模块与《剑星》《鬼武者》现装逐字节相同；RE9 宿主不变；RE9 源码包重生。打包清单 `Development/results/package-039-20261001/checklist.md`。

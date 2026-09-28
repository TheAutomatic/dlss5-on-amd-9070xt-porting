# 更新日志

[English](CHANGELOG.md) · README 里的更新记录表是一行一版的摘要；这里按版本展开：改了什么、效果、开关、是否逐位、对应的实验目录。版本从旧到新，新版本加在最后。

说明：
- 「逐位」指快速链输出与上一版一位都不差（EXACT 与 AE 都算）。0.01 之后精确参考链冻结当裁判，快速链对它约 42 dB PSNR。
- 「离线」是只跑网络的测试台（1000 帧弃前 200 取均值），「900 档 / 1080 档」是网络处理 1600×960 / 1920×1152。游戏内帧率除注明外为《剑星》、RX 9070 XT。
- 没测过的数字不写。实验记录在 `Development/results/<目录>/`，过程在 `Development/DevHistory.md`。

## 早期版本（0.01～0.23）

这一段的细节就是 README 更新记录表对应行，这里只列要点。

| 版本 | 日期 | tag 提交 | 要点 |
|---|---|---|---|
| 0.01 | 09-08 | 2cbccf6e | 精确移植终点：71 块全走 wave 矩阵核，15 帧与原版逐位一致；测试台 186 ms，约 5 fps |
| 0.02 | 09-08 | 75103c80 | 快速链开始（精确链冻结当裁判）：FP32 硬件累加、E4M3 操作数；接上时序；112 ms |
| 0.03 | 09-08 | afc4c2d4 | 硬件 f16/E4M3 转换、QKV+归一化合核等；62.7 ms，约 15 fps |
| 0.04 | 09-09 | a4b345a4 | 延迟提交环、命令列合批、噪声前缀 ALU 生成；23～25 fps |
| 0.05 | 09-09 | 691a4331 | 输出侧时间平滑、ViT 注意力 FP8；24～25 fps |
| 0.06 | 09-09 | 7ac30c8f | 仓库重整、GPU 探针默认关、pre 块输出 E4M3；27～28 fps |
| （0.07） | 09-09 | 无 tag | 跳过三块（有损，40.7 dB）、显存 6.8→3.75 GB；29 fps |
| 0.08 | 09-10 | 007e20d1 | 一批逐位的布局/直读优化；《浪人崛起》XeSS 路径；测试台 24.4 ms，36～37 fps |
| 0.09 | 09-11 | 40e90157 | 升采样投影 f16 光栅（逐位，−0.2 ms）；Magpie 版可用于任意游戏（约 30 fps） |
| 0.10 | 09-11 | 389bd464 | 黑块根因修复：E4M3 转换前夹到 ±448（`DLSS5_BUILD_C32_SAT_CAST`） |
| 0.11 | 09-11 | 587c7065 | 接管时间 20～30 秒 → 约 3.5 秒（预读权重、批量常驻、shader 磁盘缓存） |
| 0.12 | 09-12 | 1d7883ac | 屏幕提示（分辨率不对/初始化中/失败）；`DLSS5_NOTICE` |
| 0.13 | 09-12 | 284078ec | `DLSS5_SHOW_FPS`；按输出状态接管 |
| （0.14） | 09-12 | 无 tag | Magpie 整包：FPS 三秒刷新、清理 |
| 0.15 · [包](https://pan.quark.cn/s/1601ca8f80ae) | 09-13 | a100c68c | 窗口 ≤1920×1080 按比例适配（`DLSS5_FIT_INPUT=1`）；另有 [0.15-900P](https://pan.quark.cn/s/a5339e4c8549) |
| 0.20 · [包](https://pan.quark.cn/s/3c8b5329353c) | 09-17 | 281def3e | **HIP 后端**：COMGR 编 gfx1201 内核，与 DX12 链逐位一致；900p 约 15.5 ms、游戏内 900p 52 fps |
| 0.21 · [包](https://pan.quark.cn/s/85a507a744bd) | 09-17 | a58939f7 | `DLSS5_NETWORK_HEIGHT=auto` 自动选档；与 0.20 逐位 |
| 0.22 · [包](https://pan.quark.cn/s/03f9995d0551) | 09-17 | cd788282 | 900 档补边 1024→960 行（−0.9 ms）；**输出变化**（对 0.21 约 31.5 dB），`900w` 可回旧布局 |
| 0.23 · [Magpie](https://pan.quark.cn/s/548e52cc4f49) · [OptiScaler](https://pan.quark.cn/s/8b5a402012a2) | 09-18 | 8df03155 | 多 GPU/核显机器按适配器名选 HIP 设备；与 0.22 逐位 |

## 0.24（09-19，tag 381c901f）

下载：[OptiScaler](https://pan.quark.cn/s/1f32ffbd2e96)（HIP）

- **改了什么**：前置超分路线——游戏低分辨率颜色 → DLSS5 → OptiScaler 的 FSR 3.x/4 → 最终输出，同队列异步提交。只改本项目插件；OptiScaler 本体、权重、内核不变。
- **效果**：《剑星》2560×1440、FSR 质量档（输入 1707×961）约 34～35 fps。
- **行为变化**：DLSS5 历史暂时每帧重置（FSR 时序保留）；网络输入仍须 ≤1920×1080。
- **逐位**：网络输出与 0.23 相同。

## 0.24.1（09-19，tag 8ef8e402）

下载：[OptiScaler](https://pan.quark.cn/s/4f73a54d0ff9)（HIP）

- **改了什么**：配置/资产路径查找——DLL 被加载到 `_storage_` 等子目录、旁边没有 `DLSS5-AMD` 时，继续到游戏 EXE 旁查找，避免误读开发目录的旧配置。
- **逐位**：内核与权重不变。
- 不解决《生化危机 9》同一命令列表内的前置接入限制。

## 0.24.2（09-19，tag 605b041d）

下载：[OptiScaler](https://pan.quark.cn/s/f74aaa5c7f9a)（HIP）

- **改了什么**：插件在没有前置任务时不再每次绘制都查配置、锁任务表；减少日志计数争用；F6 关闭时直接旁路前置捕获和颜色复制。同日重打完整包，补上 FPS/状态显示开关。
- **效果**：《剑星》主城约 49 fps（此前约 31 fps，CPU 开销）。
- **逐位**：内核与权重不变。

## 0.25（09-19，tag 31fc6b32）

下载：[Magpie](https://pan.quark.cn/s/09630ed99606) · [OptiScaler](https://pan.quark.cn/s/636691131c5f)（HIP）

- **改了什么**：C32/多头注意力复用指数计算、简化倒数；中间特征和解码输出以 FP8 字节传递；解码完整分组走快速路径。修复 900 档尾部漏写、中文路径加载失败。**新增 gfx1200（9060/XT）内核**，与 gfx1201 按设备自动选择。
- **效果**：Magpie 1080P 仅 DLSS5 约 37 fps，与之前基本持平。
- 9060/XT 当时待实机反馈。

## 0.26（09-19，tag 8dc76ccc）

下载：[Magpie](https://pan.quark.cn/s/7ce2ca11db43) · [OptiScaler](https://pan.quark.cn/s/c880a70f0824)（HIP）

- **改了什么**：FFN 直接读 FP8 字节片段（省入口共享缓冲暂存和两道同步）；C256 权重初始化时预排成连续矩阵片段。补齐漏打包的 R11G11B10 解码 shader（修复《匹诺曹的谎言》低效果品质黑屏）；增加 shader 编译/绑定校验。
- **校验**：包内文件及 44 种 shader 组合校验通过。

## 0.26.1（09-20，tag b778c511）

下载：[OptiScaler-REFramework](https://pan.quark.cn/s/624c87a6aa11)（HIP，RE9 专用）

- **改了什么**：RE9 这类特殊接入的后置 HIP 路线——R10G10B10A2/FP16 转换、FSR 后处理、固定 900P 计算、1080P SDR 输出保护；状态/分辨率/Present 帧率与 F7 信息开关。集成 REFramework、OptiScaler、ReShade、完整模型与双架构内核，沿用 0.26 优化。
- 仅《生化危机 9》实测，普通游戏用通用包。

## 0.27（09-20，tag e8f4b4a4）

下载：[Magpie](https://pan.quark.cn/s/ec3a3282aa76) · [OptiScaler](https://pan.quark.cn/s/004278159ed8) · [OptiScaler-REFramework](https://pan.quark.cn/s/010683548f68)（HIP）

- **改了什么**：精确流式 ViT 注意力，减少中间存储与重复读取，保持原计算与舍入。可选 R3 自适应复用（变化检测、静止延长缓存、融合提交），**默认关**。
- **逐位**：流式 ViT 与原计算一致；自适应复用是可选的有损开关。
- 三包各 44 个 shader 变体及 ZIP 逐文件校验通过；不含 INT4/剪枝。

## 0.28（09-22，tag cdfd6b6e）

下载：[Magpie](https://pan.quark.cn/s/11547f398eb4) · [OptiScaler](https://pan.quark.cn/s/f7f423b0ea3a)（HIP）

- **改了什么**：六项无损内核优化——RGB 共用读取、C128/C256 零填充跳过、ViT 展开/投影与解码投影固定尺寸。
- **效果**：《剑星》实玩效果/帧率基本不变。
- RE9 的 0.28 下载已撤下，改用 0.28.1。

## 0.28.1（09-22，tag b74dbc72）

下载：[OptiScaler-REFramework](https://pan.quark.cn/s/1375693a0d21)（HIP，RE9 专用）

- **改了什么**：真实输入超限时在 HIP 初始化前拒绝并保留原始超分；初始化失败安全回滚，改回有效尺寸可恢复；保护未退休帧。宿主与 runtime 需配套更新；源码与 TheAutomatic 署名随包。
- **校验**：10 组 / 12 提交帧回归与用户初步实玩通过。

## 0.29（09-23，tag cda8171d）

下载：[Magpie](https://pan.quark.cn/s/fe1b6af36cad) · [OptiScaler](https://pan.quark.cn/s/209e04e7acaf) · [OptiScaler-REFramework](https://pan.quark.cn/s/505d38a63a85)（HIP）· [Google Drive 镜像](https://drive.google.com/drive/folders/1VPsX33sLTxBG4J8kJ_IzBDlkbBTCc5Eo?usp=sharing)

- **改了什么**：
  - 超过 1920×1080 的输入不再拒绝：缩到 1080 档跑网络，再按原版 codec 方式还原到原分辨率（`DLSS5_FIT_LARGE=1`，issue #6）。
  - 自 0.28 以来六项逐位优化：栅栏作用域、C32 折叠 FFN、字节链 + 向量化输入、注意力寄存器化、in16 别名、FFN 尾段转置。
- **效果**：内核约 −7%；《剑星》900P 约 60 fps、2K Native AA 44 fps；RE9 Native AA 实测可用（超宽屏未实机）。
- **新开关**：`DLSS5_FIT_LARGE=1`（模板默认开）。
- **逐位**：内核优化逐位；FIT_LARGE 是新的输入路径。
- RE9：宿主不变、runtime 更新。

## 0.30（09-25，tag 4adecd03）

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

## 0.31（09-26，tag 1c3950c8）

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

## 0.32（09-26，tag e1d9bd3d）

下载：[夸克](https://pan.quark.cn/s/b805e071405c) · [Gofile 镜像](https://gofile.io/d/CZ67LYIc)（三个包）

- **改了什么**：
  - 显存池：HIP 导入的 D3D12 共享缓冲区驱动不归还，改为按档位复用（切 40 次 +3 GB → 平台）。
  - C32 宽读（向量输入读取）。
  - RE9 runtime 读 flags（`DLSS5_HIP_*` / `SKIP_BLOCKS` / `FIT_LARGE` / `NETWORK_HEIGHT`），默认开 0.31 新核，兼容老宿主两参数 `EnqueueHip`；合入 PR #9。
- **效果**：C32 宽读 −0.8% / −0.9%；离线 900 档 10.74 ms、1080 档 15.01 ms；RE9 中画质 2K 高质量 54、原生 AA 38。
- **逐位**：C32 宽读逐位。
- **实验目录**：`results/vram-leak-20260926`、`c32-wave-phase-20260926`、`re9-runtime-flags-20260926`。

## 0.33（09-27，tag 2cb0ab90）

下载：[夸克](https://pan.quark.cn/s/6bb64e46ab67) · [Gofile 镜像](https://gofile.io/d/8yAjJX1b)（三个包）

- **改了什么**：
  - FP8 打包：c32-wave1 的 `CW_PACK8`、c64-wave2 的 `W2_PACK8`——一条 `cvt_pk` 转两个值写进片段字。
  - 插件：前置状态行显示 AE/EXACT；F7 开关屏幕文字；共享的环境选项解析。
- **效果**：离线 900 档 10.74→9.80 ms、1080 档 15.01→13.64 ms（约 −9%）。《剑星》1080P 原生 AA EXACT 主菜单 49～50、常见场景 53～54。
- **逐位**：相对 0.32 逐位。
- **实验目录**：`results/c64-block-fused-20260927`、`pack8-20260927`。
- RE9：宿主/runtime 与 0.32 相同（只换模块）。

## 0.34（09-27，tag 9bd416fa）

下载：[夸克](https://pan.quark.cn/s/4b572b0a5b81) · [Gofile 镜像](https://gofile.io/d/cfHqVzD1)（三个包）

- **改了什么**：
  - fmed3 clamp（`HIP_FMED3_CLAMP`、C32 `HIP_FP8_SAT_MODE 3`）与 `W2_PACK8 6`（分段 FP16_OVFL + fma(x,y,+0) 打包）；整套模块由 `hip/build-modules.ps1` 按生产配方编出（3 个回退模块从源码重编）。
  - PDL 计数回绕保护；卸载时释放 PDL 缓冲。
  - RE9 宿主 aa3761f2：跟随实际执行拆分列表的队列 + 8 次评估看门狗（《鬼武者》）；runtime ca6d6bdc：切档泄漏 35 MB→0，每次尺寸/档位变化记几何日志；重新生成宿主/runtime 源码包。
- **效果**：《剑星》1080P AA EXACT 主菜单 50～51 / 场景 54；RE9 中画质 2K 高质量 58、原生 AA 41；《鬼武者》2K 质量约 60。
- **逐位**：相对 0.33 逐位。
- **实验目录**：`results/fmed3-ovfl-20260927`、`ovfl-census-20260927`、`c64-hand-asm-20260927`、`pdl-audit-20260927`、`onimusha-presr-20260927`、`re9-runtime-leak-20260927`。

## 0.35（09-27，tag ec96774d）

下载：[夸克](https://pan.quark.cn/s/83e6172e6c79) · [Gofile 镜像](https://gofile.io/d/NnF4GitT)（三个包）

- **改了什么**：
  - C32 三轮：去重复 FP8 往返（`CW_DIRECT_OUT`、`CW_PREFIX_DIRECT_OUT`）、RTZ/LDS 写向量化（`CW_RTZ_PAIR`）、分段饱和模式（`CW_PACK_MODE_MASK`）、prefix/finish 完整窗口快路径（`CW_PREFIX_FULL_TILE` 等）。
  - ViT 字节流（`DLSS5_HIP_VIT_STREAM=3`，新 `vit-stream` 模块：注意力输出以字节直接喂投影，兼容自适应复用）。
  - 插件 4151123e；每架构 30 个模块；RE9 runtime 432d8ccf（同一开关，宿主 aa3761f2 不变）。
- **效果**：离线 900 档约 9.3 ms、1080 档约 12.75 ms。《剑星》1080P AA EXACT 约 56.7（0.34 为 54）；RE9 中画质 2K 高质量 58～59、原生 AA 42。
- **新开关**：`DLSS5_HIP_VIT_STREAM=3`（模板默认）。
- **逐位**：相对 0.34 全部逐位。
- **实验目录**：`results/c32-aco-20260927`、`c32-round2-20260927`、`c32-round3-20260927`、`vit-bytestream-20260927`。

## 0.36（09-28，tag 待补）

下载：[夸克](TODO-QUARK) · [Gofile 镜像](TODO-GOFILE)（三个包）

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

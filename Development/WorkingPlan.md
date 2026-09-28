# 当前工作计划（覆盖式，不续写；最后更新 2026-09-28 23:55，朱雀）

> 开 session 先读这页。**这是项目唯一的"现状 + 规矩 + 为什么"**：实验过程与数据进 DevHistory.md（只追加），版本改动进 CHANGELOG（中英两份），其余一律改这页（整页重写，读一遍再重写，该删的删）。
> 节奏：过日子式，没有 deadline。优先做有具体瓶颈证据、可逐位验证的小实验，够用就交。

## 当前基线（0.36，09-28）

- **0.36 已发布**（09-28 23:36，夸克 https://pan.quark.cn/s/e5afdaca0769 + Gofile https://gofile.io/d/Z1hWdjcB，tag 0.36 = 2a72897d）：add-on d2290ad7、RE9 runtime 7ce2bc21 + 宿主 aa3761f2（沿用）、输入 shader 5be59a41、每架构 30 模块（清单 `results/fusion-round3-20260928/package-036-checklist.md`、`HIP-SHA256SUMS`）。脚本 `tools/package-036.ps1`（下次复制它）；Magpie 包自带 `ReShade.ini`（`TutorialProgress=4`，去 Home 引导遮罩）。
- **0.36 相对 0.35**：ACO 对齐两刀（C32 去 NaN 规范化、C64～C256 有界倒数）、**float FMA（09-28 起新逐位基准，与 0.35 不逐位，对 NVIDIA 误差持平）**、`DLSS5_DIRECT_IO`（输入直写，发布默认 1）、C256 整块融合（1080）、C512 QKV+attention 融合、C64/C128 FFN 权重复用、C32/C64/C128 上采样与首块融合、帧时间日志 `DLSS5_FRAME_STATS`。派发 214 → 1080 档 182、900 档 198。离线 900 −0.79ms（−8.5%）、1080 −1.13ms（−8.9%）。
- **剑星本机**（EXACT 静止）：1080P 原生 AA **60**（窗口模式 DWM 60Hz 封顶，量不出提速）；**2K（2560×1440）原生 AA 54**（新标尺；C512 融合版 52～53）。
- **各游戏现装**：
  - 剑星：add-on d2290ad7 + 0.36 模块，flags `DLSS5_DIRECT_IO=3`（含 FSR 输出直交，仅剑星现场）、`MAKE_RESIDENT_EVERY=60`、`FRAME_STATS=5`。备份 `D:\DLSSNR-Lab\hip-backend\fusion-round3\backups\stellar-20260928-220957`。
  - RE9：0.35 全套（0.36 runtime 只在包内冒烟过，未装进游戏）；中画质 2K 高质量 58～59、原生 AA 42。
  - 33 号远征队：0.35 常规包 + 第五刀；鬼武者：0.33 RE9 包 + 0.34 模块；匹诺曹：旧版，贴 60 不作对比。
- **对手（09-28 剑星实测 + 静态对照）**：Daniel 0.5.0 默认 fast 档（f32 累加、e4m3 一次舍入、近似 rsqrt/rcp）网络 9.4～10.0ms，reference 档 11.0ms；他 1080 只算 1088 行、post 位移 0（有损简化，不追）。mochizuki 0.0.2.2（Claude Code 合写）Windows 版自称与 Linux 差 48.6dB。**我们 0.36 在完整 1152 行、NVIDIA 位移下与他们打平。** 换装对照用 `D:\DLSSNR-Lab\daniel-050\swap.ps1 daniel|ours`，看他日志 `dlssnr_on_amd.log` 的 network 均值。

## 正在进行

- 无。0.36 刚发，等 Zero 定下一步。

## Zero 的标准与取舍（为什么这样定）

- **测帧**：剑星 **2K 原生 AA + F8 EXACT**，读黄字小数（1080P 已被 60Hz 封顶）。只用 9070 本机数据，**Splashtop 远程读数不作数**（编码占 GPU、抖动大）。帧率随画面运动起伏是游戏渲染本身；比版本只用"同一位置、静止、简单画面"。网络本身的快慢以离线 ABBA 为准；帧时间日志 `frame-stats.txt` 由 agent 自己去 9070 取，不让 Zero 发。
- **逐位是硬门槛**：对 09-28 float FMA 基准（`results/float-fma-20260928/new-baseline-hashes.csv`，0.36 即此基准）一个比特都不差，7 用例、EXACT/AE 都要、两档 ABBA；有反例就不改。**逐位是"对上一版"，不是"对 NVIDIA"**——最早版本才与原版全字节一致，此后转 fast、跳层、float FMA 都是 Zero 拍板的有记录偏离。误差会逐层逐帧放大，所以非拍板不偏离。
- **偏离的做法**：先核实（查 NVIDIA 原文/量 RMSE），Zero 批准后作为一次单独偏离合入，新版本成为新基准，CHANGELOG 写明。
- **稳定性不操心**：只修能复现的。**风险不换速度**：PDL 保持 1。
- **发布**：夸克 + Gofile；README 中英"当前版本"段 + 更新记录表（按版本从旧到新，一句话，**不写内部代号闇/Yami/朱雀/分身**）+ CHANGELOG 中英详细一节（改了什么/效果/新开关/是否逐位/有损/results）；链接回来后在打包源码提交上打 tag。

## 派活方法

- **分工**：Zero 给意图 + 验收 + 转发给闇 → 朱雀拆解、写任务单、记账（本页、DevHistory、CHANGELOG、打包、README）→ 分身和闇执行。
- **探路给分身，采矿给闇**；任务单三要素：从哪下手、别走哪几条路、什么时候停。放 `conversation/<日期>/`，Zero 转发。
- **对照物比招式管用**（09-28 教训）：照抄 mochizuki 的改动一轮 null；改成"挑一两段和 ACO/Daniel 的 ISA 逐条对齐、每条多出的指令归类（语义必须/编译器产物/源码写法）"后连续出刀。Daniel 是同 HIP 同编译器同算术，比 ACO 更直接；他的 168 个内核已解包在 DGX scratchpad `d050/`（会丢，丢了重跑 `tools/closed-inspect/extract.py`）。
- **git 协作**：主进程只 `git add <具体文件>`，绝不 `commit -a`；分身在同仓库改东西时，主进程提交先只本地 commit，等分身 push 时带上（工作区有它的未暂存改动时 pull --rebase 会失败）。改代码的分身用 worktree。等后台任务用完成通知，不写轮询。

## 研究判断（技术主线的"为什么"）

- **RDNA4 上 FP8 WMMA 与 VALU 不重叠**：删 VALU 就是省时间。但 0.36 后我们 C32/C64 普通向量指令已不比 Daniel 多，剩下差距主要在**派发/融合与访存**（显存读取请求约是他的 2 倍）。
- **融合赚不赚看组织方式**：旧 C256 整块融合更慢，学 Daniel"多组 token 共用一份权重"后变快（权重读取减半、寄存器 190→154）。少读取不一定兑现（去清零、C32 权重缓存都 null），要整网实测。
- **LLVM 做不到的要源码显式写**：`mul`+`add 0` 收缩、NaN 规范化、f32↔f16 往返、已知范围的除法（写成有界倒数）。手改汇编只当显微镜。
- **按调用次数加权再选目标**；访存受限的核砍 VALU 不赚，要改数据形态；C512 不是并行度不足。
- **网络外流水线**：拷贝不是大头（直写 IO 只省 0.02～0.05ms），剩余差距更可能在 HIP↔D3D 交接（我们共享 fence 挂起等唤醒，Daniel GPU 轮询标志）。

## B. 优化候选（逐位；按"收益 × 把握"排）

1. **C512 剩余派发**：79 对 Daniel 64（他 16 块×4，我们 13 块有效，不能直接相减）；需要新内核，按 Daniel 组织再看。
2. **ViT**：49 对 40（每块 6 对 5 + 入口打包）；本轮 P/G/Q/R 候选逐位但不赚，要新的组织证据。
3. **HIP↔D3D 交接改 GPU 轮询**（`results/frame-breakdown-20260928` 第 4 项）：收益待测，会碰看门狗（Daniel 用 1 像素 draw 分片自旋规避）。
4. **900 档**：C256 整块在 900 仍走分体（新分组变慢）；2K 质量档落 900，值得换思路再看。
5. 小件：C256 FFN 标量量化/地址开销（`results/aco-lineup-20260928` 逐条表）；ViT QKV 归一化段；C32 对角残差跳过全零 K16 半块（约 −0.1～0.2%）。
6. 杂项：`MAKE_RESIDENT_EVERY=60` 疑似每 60 帧一次约 30ms 尖刺（p99），改 0 测一次（C.C. 令"把延迟波形拉直"）；常规 OptiScaler 包也带 ReShade 却无 ini，新用户可能见引导遮罩，下版照 Magpie 补；`validate-modules.ps1` 修路径；帧时间日志 Magpie 路线未接。

**已交负账（别重复）**：mochizuki 0.0.2.2 各路线（I/P/S/V/F/O/G/H，`results/mochizuki-022-20260928`）；C512 FFN M32、900 C256 新分组、ViT byte 出口/入口 gather-pack、C64/C128 Down 融合、去清零、C32 权重缓存。

## C. 需要 Zero 拍板（有损）

- **fast 档**（Daniel 默认那套：e4m3 一次舍入、近似 rsqrt/rcp、f32 累加等）：他 fast 比 reference 快约 1ms；可做成 EXACT 之外单独一档。
- ViT QKV 改 FP8（估整网 2～4%）；6b（−1.1%，PSNR 58dB）。
- 几何：缩到 1088 行（估 0.70ms，NVIDIA 原版是 1152，属偏离）；加档 1728×1024（画质向）。
- 不做：整网隔帧（运动拖影）；RDNA3 后端（无卡可测；Daniel 做法 = f16 权重副本 + f16 WMMA + 整数模拟 e4m3，VALU 约 4 倍，留作参考）。

## 产品适配与等待事项

- **PR #12（TheAutomatic）**：已回复（`conversation/20260928/pr12-review.md`）——PDL 预检 + TYPELESS 开关可合；ColorStrength 默认映射、preOnly 白点、auto_white 与调试视图冲突、R10G10B10A2 写回路径待他改/说明，建议拆 PR。等他回。
- **PRE_UPSCALE=auto**、卧龙 2 重试、自带 FSR dll 的游戏（`EnableFfxInputs=false`、必要时 `ASYNC=0`）、网友统一宿主补丁（`RE9/presr/contrib/generic-host-20260924/REVIEW.md`）——照旧等。
- 新权重传闻：Zero 说先不管。PDL acquire 论证是文档欠账，出现实际卡死再切 0。

## 机器与流程

- **授权**：编译、远程实验、回归、分析由 agent 自主执行；动 GPU 前查游戏进程，游戏运行时不换文件、不跑 GPU 冒烟；画质判断请 Zero。
- **游戏进程名**：剑星 `SB-Win64-Shipping`、匹诺曹 `LOP-Win64-Shipping`、鬼武者 `OnimushaWotS`、RE9 `re9`、33 号远征队 `SandFall*`。
- **git**：只推 297，commit 不加 Co-Authored-By；push 前 `git pull --rebase`；只 add 具体文件。
- **9070**（`ssh amd9070`）：工作根 `D:\DLSSNR-Lab\`；`hip/build-modules.ps1`（`-ExtraDefines`、`-Only`）；`hip/compare-modules.py`；完整游戏帧回放 `results/frame-breakdown-20260928/replay.ps1`（`DLSS5_BENCH_PLAIN=1` 模拟剑星非时序会话）；打好的包在 `D:\給網友打包\`。ssh 远端是 cmd，多条 PowerShell 分开调；`(x86)` 路径写进脚本文件。
- **3080 游戏本**（`ssh rtx3080`）：PATH 不全，用 `powershell -EncodedCommand`；scp 不通。
- **DGX Spark**：`~/work/aco-isa/` 有 RADV + drm-shim 假 gfx1201，离线拿 ACO ISA。
- **发布**：复制上一版 `tools/package-0xx.ps1` 改版本/哈希/变更，逐文件校验、编 44 shader 变体、压包读回；RE9 runtime 变了用 `prepare-host.py` + `bundle-source.py` 重生源码包（跑完 `git checkout Development/RE9/presr/upstream.json`）。
- **新开关必须同时在 RE9 runtime 开口**（`src/native_hip_env_options.h`、三个 flags 模板、`scripts/CONFIGURATION.md`），RE9 不适用的写明。

## 公众号素材（Zero 还没说写）

一天从被反超到追平（57→60，2K 54）；"两次舍入是不是 NVIDIA 原意"——逐位原来是对上一版；照抄对手 null、逐条对齐才出刀；Daniel 的 60 帧是刷新率上限；三家都是"人 + AI"，比的是谁更会驾驭 AI。随手发版文已写 `wechat/临时-dlss5-0.36.md`。

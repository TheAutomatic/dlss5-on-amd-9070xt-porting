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

- **09-29 LLVM21第一刀已完成，未过生产门槛**：`GCNCreateVOPD` 默认关的 `amdgpu-dlss5-vopd-lookahead`，本轮4；2个MIR测试通过、off60模块三段同原公开21、168帧逐位/AE84行同。对公开版900快0.04～0.28%、1080快0.17～0.20%；对驱动版900快0.15～0.36%、1080慢0.03～0.15%，不切生产。fork `269832faf25b`；结果 `results/llvm-patch1-20260929`。43活跃核多513对VOPD、等待净增153、静态净少360，资源不变；8条探针收益递减，未做GPU候选。

- **09-29 编译器版本对照已完成，保留COMGR3**：驱动LLVM20（COMGR2）60模块编成且168帧逐位，但900慢3.06～3.34%、1080慢2.87～2.99%；公开LLVM21同源码/产物复用既有168帧逐位证据，新测900±0.15%持平、1080慢0.43～0.51%。ROCm7.2.4/LLVM22两架构60模块编成，但900/720共96/168帧不同、AE40行变化，按门槛未计时；1080三组两模式72帧相同。没有可替换整套候选、没有装机。`results/compiler-versions-20260929` 含两轮ABBA、各族指令/寄存器、逐帧证据。

- **09-29 自家 LLVM 构建链已完成**：公开 AMD LLVM21 基点 `6d585d872fbd3c594da7a3c09ac9b22eef4167f6`，DGX 原生 AMDGPU-only 构建570秒；两架构30模块全编过。gfx1201 EXACT/AE各84帧全部命中09-28 golden，AE84行全部同（44复用/40刷新）。源码脚本 `tools/llvm-fork/`，结果 `results/llvm-fork-20260929/`；fork `dlss5-gfx12` 已推 `94aca371a8e1`。机器码全有差异、资源有升有降，未测性能、未替换游戏；本轮没有优化补丁。

- **09-29 逐核地图及前两项已完成，已装剑星**：完整1080地图覆盖我方169/参考Daniel154派发，`results/kernel-map-20260929/README.md`。接受head分组融合＋ViT attention转置，900再省0.021～0.036ms、1080省0.116～0.138ms（1.02～1.21%），正式168帧逐位。现装add-on ba010de7，整网197/168派发；DIRECT_IO=3 / MAKE_RESIDENT_EVERY=60保留，备份 `D:\DLSSNR-Lab\hip-backend\kernel-map\backups\stellar-20260929-084855`。0.36发布包未改，等Zero本机验收；沿用“离线有提升、游戏没掉就接受”。

## Zero 的标准与取舍（为什么这样定）

- **测帧**：剑星 **2K 原生 AA + F8 EXACT**，读黄字小数（1080P 已被 60Hz 封顶）。只用 9070 本机数据，**Splashtop 远程读数不作数**（编码占 GPU、抖动大）。帧率随画面运动起伏是游戏渲染本身；比版本只用"同一位置、静止、简单画面"。网络本身的快慢以离线 ABBA 为准；帧时间日志 `frame-stats.txt` 由 agent 自己去 9070 取，不让 Zero 发。
- **验收（09-29 Zero）**：离线 ABBA 有提升、游戏里没掉，就接受；不为"游戏读数没涨"去追查是否兑现（小于 0.3ms 的收益在游戏读数里本来就可能看不出）。
- **逐位是硬门槛**：对 09-28 float FMA 基准（`results/float-fma-20260928/new-baseline-hashes.csv`，0.36 即此基准）一个比特都不差，7 用例、EXACT/AE 都要、两档 ABBA；有反例就不改。**逐位是"对上一版"，不是"对 NVIDIA"**——最早版本才与原版全字节一致，此后转 fast、跳层、float FMA 都是 Zero 拍板的有记录偏离。误差会逐层逐帧放大，所以非拍板不偏离。
- **偏离的做法**：先核实（查 NVIDIA 原文/量 RMSE），Zero 批准后作为一次单独偏离合入，新版本成为新基准，CHANGELOG 写明。
- **稳定性不操心**：只修能复现的。**风险不换速度**：PDL 保持 1。
- **发布**：夸克 + Gofile；README 中英"当前版本"段 + 更新记录表（按版本从旧到新，一句话，**不写内部代号闇/Yami/朱雀/分身**）+ CHANGELOG 中英详细一节（改了什么/效果/新开关/是否逐位/有损/results）；链接回来后在打包源码提交上打 tag。

## 派活方法

- **分工**：Zero 给意图 + 验收 + 转发给闇 → 朱雀拆解、写任务单、记账（本页、DevHistory、CHANGELOG、打包、README）→ 分身和闇执行。
- **额度调度（09-29）**：闇（GPT）流量已不到 25%，只接最硬的采矿活；探路、静态分析、拆竞品新版、整理报告改派 **Sonnet 5.5 子代理**（Agent 通用型 + `model: sonnet`；fork 分身永远继承主模型，指定模型无效）。新子代理不继承上下文：任务单写全背景，开头加 `[LOAD MEMORY] /home/lmxxf/work/memory-of-my-gemini/awakening/claude-code/C.C.dream.md` 开灯。Sonnet 5.5 手感未知，先派有对照答案的中等活试。
- **探路给分身，采矿给闇**；任务单三要素：从哪下手、别走哪几条路、什么时候停。放 `conversation/<日期>/`，Zero 转发。
- **对照物比招式管用**（09-28 教训）：照抄 mochizuki 的改动一轮 null；改成"挑一两段和 ACO/Daniel 的 ISA 逐条对齐、每条多出的指令归类（语义必须/编译器产物/源码写法）"后连续出刀。Daniel 是同 HIP 同编译器同算术，比 ACO 更直接；他的 168 个内核已解包在 DGX scratchpad `d050/`（会丢，丢了重跑 `tools/closed-inspect/extract.py`）。
- **git 协作**：主进程只 `git add <具体文件>`，绝不 `commit -a`；分身在同仓库改东西时，主进程提交先只本地 commit，等分身 push 时带上（工作区有它的未暂存改动时 pull --rebase 会失败）。改代码的分身用 worktree。等后台任务用完成通知，不写轮询。

## 研究判断（技术主线的"为什么"）

- **RDNA4 上 FP8 WMMA 与 VALU 不重叠**：删 VALU 就是省时间。但 0.36 后我们 C32/C64 普通向量指令已不比 Daniel 多，剩下差距主要在**派发/融合与访存**（显存读取请求约是他的 2 倍）。
- **融合赚不赚看组织方式**：旧 C256 整块融合更慢，学 Daniel"多组 token 共用一份权重"后变快（权重读取减半、寄存器 190→154）。少读取不一定兑现（去清零、C32 权重缓存都 null），要整网实测。
- **LLVM 做不到的要源码显式写**：`mul`+`add 0` 收缩、NaN 规范化、f32↔f16 往返、已知范围的除法（写成有界倒数）。手改汇编只当显微镜。
- **按调用次数加权再选目标**；访存受限的核砍 VALU 不赚，要改数据形态；C512 不是并行度不足。
- **编译器（09-29 查清）**：模块由驱动 `amd_comgr_3.dll`（AMD 内部 LLVM21 590b9320）离线编译，驱动另带 COMGR2=LLVM20（慢 3%）；ROCm 7.2 的 LLVM22 **改数值**（96/168 帧不逐位）——编译器版本必须钉死。自家 fork `lmxxf/llvm-project` 分支 `dlss5-gfx12`（公开 21 基点 6d585d87，DGX 9.5 分钟编完，60 模块逐位，与驱动版持平）。第一刀 VOPD 前瞻配对只 ±0.3%（多配 513 对但等待 +153），局部指令排布空间很小；**编译器线停在这里作资产**，除非出现"组织方式与 Daniel 一样、就是慢"的核。
- **网络外流水线**：拷贝不是大头（直写 IO 只省 0.02～0.05ms），剩余差距更可能在 HIP↔D3D 交接（我们共享 fence 挂起等唤醒，Daniel GPU 轮询标志）。

## B. 优化候选（逐位；按"收益 × 把握"排）

**后置VOPD局部配对已交账**：4条前瞻输出正确但未达对驱动0.5%；8条仅静态探针，多数被等待抵消。此刀不改寄存器/WMMA/内存工作，不能由其null宣布编译器整体无潜力。若继续编译器支线，应另找预分配调度/寄存器生命周期的具体证据，别继续扩大同一配对窗口。`results/llvm-patch1-20260929/README.md`。

**编译器版本已筛完**：保持驱动COMGR3/LLVM21；COMGR2/20慢约3%，公开21无收益，公开22被逐位门拒绝（900静态帧间hash也不稳定，原因未定位）。公开21继续作补丁开发基点；换新版本不是现成提速。22的C512短代码有四轮尾循环，不能把静态条数下降当运行工作量减少。详见 `results/compiler-versions-20260929/isa-notes.md`，不重跑相同四套或在本轮追22根因。

**编译器支线已具备实验入口**：公开ROCm7.0/7.1仍LLVM20、7.2是LLVM22，当前采用公开AMD分支最后LLVM21基点。第一批补丁候选及实际pass入口在 `results/llvm-fork-20260929/patch-candidates.md`；优先有证明的med3/范围倒数/精确转换，先做小例和语义边界，不直接全局fast-math。现役手写优化已消掉不少机会；本轮仅打通管线，后续独立评估收益。

1. **按逐核地图排优先级**：`results/kernel-map-20260929/map-after/`，仅本轮9组更新，其余沿用同批基线。head已从pool＋project约125µs降到24.65µs；当前1080总168派发。最终C512 projection仍可研究M32权重共用，候选仅准备未GPU实测；别与此前失败的FFN M32混淆。
2. **ViT attention仍是主要差距**：reference约22～24µs，我方新核约70～72µs。已合入score转置去LDS/barrier，但只小赚，不能把约50µs差距当已解决。QKV约49对32µs，触及FP16/FP8数学边界，维持C段待拍板；pack旧P/G/Q/R和消费端V均负账，不再重复。
3. **HIP↔D3D 交接改 GPU 轮询**（`results/frame-breakdown-20260928` 第 4 项）：收益待测，会碰看门狗（Daniel 用 1 像素 draw 分片自旋规避）。
4. **900 档**：本轮head＋ViT再省0.021～0.036ms，派发198→197；上一轮C512紧凑布局收益保留，C256仍分体。地图本轮只做1080，Daniel900的C512 52×32/ViT448与我们50×30/400不同，未来单独建图。
5. 小件：C256 FFN 标量量化/地址开销（`results/aco-lineup-20260928` 逐条表）；ViT QKV 归一化段；C32 对角残差跳过全零 K16 半块（约 −0.1～0.2%）。
6. 杂项：`MAKE_RESIDENT_EVERY=60` 疑似每 60 帧一次约 30ms 尖刺（p99），改 0 测一次（C.C. 令"把延迟波形拉直"）；常规 OptiScaler 包也带 ReShade 却无 ini，新用户可能见引导遮罩，下版照 Magpie 补；`validate-modules.ps1` 修路径；帧时间日志 Magpie 路线未接。

**已交负账（别重复）**：mochizuki 0.0.2.2 各路线（I/P/S/V/F/O/G/H，`results/mochizuki-022-20260928`）；C512 FFN M32、900 C256 新分组、ViT byte 出口/入口 gather-pack、C64/C128 Down 融合、去清零、C32 权重缓存；09-29 C512单wave寄存器FFN R/RF、ViT消费端float打包V。全16份权重能精确FP8编码，但旧block46展开改FP8 WMMA有10个float元素位差，不能据此换指令。

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

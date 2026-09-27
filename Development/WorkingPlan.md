# 当前工作计划（覆盖式，不续写；最后更新 2026-09-28 07:35，朱雀）

> 开 session 先读这页。**这是项目唯一的"现状 + 规矩 + 为什么"**：实验过程与数据进 DevHistory.md（只追加），其余一律改这页（整页重写，读一遍再重写，该删的删）。不要另开别的工作日志——两份日志等于没有。
> 节奏：过日子式，没有 deadline。优先做有具体瓶颈证据、可逐位验证的小实验，够用就交。

## 当前基线（09-28 早）

- **0.35 已发布**（09-27 21:36，夸克 https://pan.quark.cn/s/83e6172e6c79 + Gofile https://gofile.io/d/NnF4GitT，tag 0.35 = ec96774d）：add-on 4151123e、每架构 30 模块（C32 闇三刀 + vit-stream）、RE9 runtime 432d8ccf + 宿主 aa3761f2，模板 `DLSS5_HIP_VIT_STREAM=3`。脚本 `tools/package-035.ps1`（下次复制它；模块数检查 30/60）。
- **0.35 之后已进仓库、未发包**：
  - 闇第五刀 C64～C256（c64-wave2 配方加字节输入整组读取 + RTZ 配对 + 直接坐标，`results/mh-round1-20260927`）：离线 900 −0.7%、1080 −0.8%，只换模块、无新开关。
  - 帧时间日志 `DLSS5_FRAME_STATS=<秒>`（add-on + RE9 runtime，`results/frame-stats-20260928`，模板默认 0）。
- **离线网络**：900 ≈9.25、1080 ≈12.6 ms（0.32 为 10.74 / 15.01）。
- **剑星实测**（1080P 原生 AA，EXACT 黄字）：0.32 51～52 → 0.35 56.7 → 第五刀 **57.1**。帧时间日志：站立不动 p99 = max ≈ 18.5ms（抖动 ±0.5ms）；跑图时约 1% 帧 28～32ms，是游戏流式加载，不是网络。
- **各游戏现装**：
  - 剑星：add-on c38bcdd4（帧时间日志）+ 0.35 模块 + 第五刀 c64-wave2，flags `DLSS5_FRAME_STATS=5`（备份 `D:\DLSSNR-Lab\frame-stats-20260928\backups\stellar-20260928-070548`）。
  - RE9：0.35 全套；中画质 2K 高质量 58～59、原生 AA 42。同一局内切档（几何日志、0 MiB）仍未实机走到。
  - 33 号远征队（9070，Xbox，UE5，exe 在 `Content\Sandfall\Binaries\WinGDK`）：0.35 常规包 + 第五刀 c64-wave2；可玩。
  - 鬼武者（9070，Xbox）：0.33 RE9 包 + 宿主 aa3761f2 + 0.34 模块；2K 质量约 60，可玩。
  - 匹诺曹：旧版，贴 60，不作对比。
- **对照**：mochizuki DLSSNR-AMD 0.0.2.2（09-28）：Linux 1080p 5.60ms；Windows 9.4 → 7.79ms（去掉 AMD Windows 编译器保留的 f32→f16→f32 往返——与我们 COMGR 同一家编译器）。我们 1080 折回 1080 行约 11.8ms，差约 1.5 倍。

## 正在进行

- **闇：对照 mochizuki 0.0.2.2**（任务单 `conversation/20260928/yami-mochizuki-022.md`，09-28 07:20 起）：① 全网 f32→f16→f32 往返普查（加权），可证明无损的去掉；② per-tile 计数器扩到 C512/ViT（我们 C512 PDL 曾与现有 PDL 叠加不赚，看他为何能赚）；③ 他其余改动逐条判断。门槛：一档整网 ≥0.5%。
- **9070 同一时间只给一个执行者跑 GPU 测试**（ABBA 计时互相干扰）。闇在跑时不派会用 GPU 的分身。

## Zero 的标准与取舍（为什么这样定）

- **测帧只用剑星**：1080P 窗口 + FSR 原生 AA，F8 切 EXACT，**读黄字 FPS 的小数**（分辨率约 0.2～0.3 帧；网络约占整帧一半，离线 −1% ≈ 游戏 +0.25 帧@56）。测 900 档：1600×900 窗口 + FSR 原生 AA（网络档 900 或 auto），避开贴 60 的场景。查卡顿：开 `DLSS5_FRAME_STATS`，站立不动对比跑图。
- **逐位是硬门槛**：每个优化与上一版输出一个比特都不差（7 用例回归，EXACT 与 AE 都要，AE 覆盖复用/刷新帧 + 900/1080 两批 ABBA）；有反例就不改。有损的等 Zero 拍板（C 段）。
- **稳定性不操心**：只修自己能复现的；理论风险和别人机器上的个例记下，不追。
- **风险不换速度**：PDL 保持 1。Zero 说"没必要增加 X 风险"时，先确认是"别担心 X"还是"别冒 X"（09-27 朱雀读反过一次）。
- 发布：夸克 + Gofile；README 中英"当前版本"段 + 更新记录表（**按版本从旧到新，新行加在最后**）；按打包源码提交补 tag。

## 派活方法

- **分工**：Zero 给意图 + 验收 + 转发给闇 → 朱雀拆解、写任务单、记账（本页、DevHistory、打包、README、公众号）→ 分身（fork）和闇执行。
- **探路给分身，采矿给闇**：分身适合"能不能/值不值"，任务单写成果门槛（"至少一个 ≥0.5% 逐位候选，否则拿证据证明挖不动"）；闇（GPT 6 Astra，Codex）适合方法已验证后一刀一刀磨，每次带成果或扎实的 null 交付。
- **任务单三要素**：从哪下手（带上他上轮的账）、别走哪几条路（已关路线）、什么时候停（门槛、够用就交、卡 2h 换下一个）。放 `conversation/<日期>/`，Zero 转给闇（只有 Zero 转发他才知道，任务单里不写"暂缓"之类给自己看的话）。
- **git 协作（09-28 教训）**：有分身在同一仓库改代码时，**主进程提交只 `git add <具体文件>`，绝不用 `commit -a`**（那次把分身未完成的 src 改动带进提交、revert 又从工作区抹掉）。改代码的分身用 worktree 隔离（Agent `isolation: "worktree"`，等于旁边多一份检出在自己分支上的 clone）；闇在他自己的 clone。
- fork 分身继承全部上下文、只回摘要；fork 后互相看不见，新信息用 SendMessage 转。等后台任务用完成通知，不自己写 `until` 轮询。

## 研究判断（技术主线的"为什么"）

- **RDNA4 上 FP8 WMMA 与 VALU 不重叠**：删 VALU 就是省时间。路线 = 看 ACO 的 ISA → 在 HIP 源码里逼 LLVM 编出同等指令（PACK8、fmed3、分段 FP16_OVFL、fma(x,y,+0)、去重复量化/往返、RTZ/LDS 向量化）。
- **LLVM 不是处处差**：VOPD、`+0.f`（−0→+0，承重）、WMMA 等待本来就对；它做不到的是 `mul`+`add 0` 收缩、自行去 NaN 规范化、去掉 f32↔f16 往返——要在源码里显式写。
- **手改汇编 = 显微镜**，不进生产。
- **按调用次数加权再选目标**；单核单段小刀整网测不出来。
- **访存受限的核（ViT、部分 C512）砍 VALU 不赚**，要改数据形态（生产者直接写消费者要的字节/half）；生产者多出的转换要算进去（C512 half 出口的教训）。
- **C512 不是并行度不足**（工作组翻倍变慢，QKV 驻留 12→14 组也不赚）。
- 分段 FP16_OVFL 用前必须 census（该段输入无 Inf/NaN、|x|≤448）。

## B. 优化候选（逐位；按"收益 × 把握"排）

1. 闇当前任务（见"正在进行"）。
2. **decoder / 上采样**（C512→C32 那几段，2×2 上采样尾部串行化）：还没按 C32/MH 的方法系统挖过，对照 ACO 的 `fswinfusedup*`。
3. C512 若再动：换切口（packed 输入生产者/主循环供数、归一化调度），不重复 mix 拆组、去重复量化、LDS 复用、half 出口、现场零扫描（`results/c512-round1-20260927`、`tier900-20260927`）。
4. 小件：ViT QKV 归一化段；C32 FFN 权重按 WMMA 片段预排；host 侧 C256 宽权重片段（约 −0.03ms）；C32 对角残差跳过全零 K16 半块（约 −0.1～0.2%，`results/c32-diag-zero-20260925`）。
5. 帧时间日志：Magpie 路线未接；RE9 runtime 只见自己被调用的帧。
6. `Development/HIP/validate-modules.ps1` 默认资产目录已不存在，修路径后纳入发包前检查。
7. 可告知 mochizuki：`v_cvt_pk_f32_fp8` 在 gfx1201 实测返回同一字节两份（`HIP/experiments/pair-unpack`），他的 fswin64 用了 64 次。

## C. 需要 Zero 拍板

- **有损**：6b（−1.1%，PSNR 58dB）、ViT QKV 改 FP8（估整网 2～4%，Daniel 的做法）。
- **加档 1728×1024**：2K 质量档不再缩 6%，画质向不提速。
- 不做：整网隔帧（3z Model interleave，运动拖影）；RDNA3 后端（无卡可测）。

## 产品适配与等待事项

- **PRE_UPSCALE=auto**：探测同列表超分后是否还有 draw/dispatch，不适合前置则回落后置（地平线 6、卧龙 2）。
- **卧龙 2**：常规包 + EnableFfxInputs=false + ASYNC=0 重试；RE9 前置宿主（鬼武者已跑通）是 RE 引擎外同类游戏的候选路线。
- 自带 FSR dll 的游戏（2077、33 号远征队）：常规包默认 EnableFfxInputs=false 已覆盖；若只见色调变化，再设 `DLSS5_PRE_UPSCALE_ASYNC=0`。
- **网友统一宿主补丁**：审单 `RE9/presr/contrib/generic-host-20260924/REVIEW.md`，等对方实测。
- 换队列修复（0.34 起）告知 TheAutomatic（未确认是否已告知）。
- 新权重（传闻 380.8.3，未证实）：等下一个原生 DLSS 5 游戏出来比 DLL；Zero：先不管。
- PDL：acquire/进展性论证是文档欠账（`results/pdl-audit-20260927`），出现实际卡死再切 0；不扩到 C512/ViT/Down/Up（除非闇这轮证明叠加赚且带回绕保护）。

## 已关路线（有新证据才重开）

- MODE.FP16_OVFL 核入口一次性（720 不逐位；分段版已采用）；`v_cvt_pk_f32_fp8` 成对解包；`v_pk_*_f16`。
- 转置布局（已在用）；C256 持久化；DF_PACK8（访存受限）；C32 激活合 fma（有反例）；C32 post 两候选。
- C512：一头一 wave、工作组翻倍、mix 拆组、去重复量化、LDS 复用、half 出口、现场全零/有限扫描。
- C32 尾部合并遍历、C32 转置尾部并宽、mapped/post 输入布局三方向、ViT group 编号重排、直达 LDS 读取、双 stream 重叠。详见 DevHistory 与各 results。

## 机器与流程

- **授权**：编译、远程实验、回归、分析由 agent 自主执行；动 GPU 前查空闲，游戏运行时不换文件；画质判断请 Zero。9070 整机交给 agent，Zero 在 3080 游戏本上对话，实测时回 9070。
- **游戏进程名**：剑星 `SB-Win64-Shipping`、匹诺曹 `LOP-Win64-Shipping`、鬼武者 `OnimushaWotS`、RE9 `re9`、33 号远征队 `SandFall*`；Magpie 空闲可忽略。
- **git**：只推 297，commit 不加 Co-Authored-By；push 前 `git pull --rebase`；只 add 具体文件。实验 exe、部署二进制不进仓库（.gitignore 已配）。
- **9070**（`ssh amd9070`）：工作根 `D:\DLSSNR-Lab\`；`hip/rtc_compile.cpp` → `hip/build-modules.ps1`（`-ExtraDefines`、`-Only`）；`hip/compare-modules.py` 比代码段；`HIP/experiments/c64-hand-asm/asm_compile.cpp` 汇编往返；部署照 `deployments/<名>/`；给游戏装包可复用 scratchpad 的 `sb-fresh032.ps1` 思路（整包解压 + 全量备份 + manifest 还原）。PowerShell：中文路径 .ps1 要 UTF-8 BOM，`(x86)` 路径写进脚本文件。
- **3080 游戏本**（`ssh rtx3080`，192.168.31.243）：ssh 会话 PATH 不全，用 `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -EncodedCommand <UTF-16LE base64>`；scp 不通，文件让它自己下载；桌面在 OneDrive 下。
- **DGX Spark**：`~/work/aco-isa/` 有 Mesa 26.2.3 RADV + drm-shim 假 gfx1201，可离线拿 ACO ISA（`results/aco-isa-20260927/tools`）。
- **发布**：以上一包为底，复制上一版 `tools/package-0xx.ps1` 改版本/哈希/变更（模块数、flags 检查要跟着改），逐文件校验、编 44 shader 变体、压包读回；RE9 宿主或 runtime 变了就用 `prepare-host.py` + `bundle-source.py` 重新生成源码包（跑完 `git checkout Development/RE9/presr/upstream.json`）；有游戏开着时 RE9 冒烟会被跳过，要补跑。
- **新功能/新开关必须同时在 RE9 runtime 开口**：`DLSS5_*` 键走 `src/native_hip_env_options.h`，三个 flags 模板与 `scripts/CONFIGURATION.md` 同步。

## 公众号素材（Zero 还没说写）

两天从 51 到 57 帧（0.32→0.35 + 第五刀）；ACO 当老师、手写汇编当显微镜；PDL 竞态与"风险不重要"；帧时间日志证明顿挫是游戏的；人给意图、AI 拆解执行的半人马分工；人+AI 产出带现实校验的数据防坍缩。

# 当前工作计划（覆盖式，不续写；最后更新 2026-09-30，朱雀）

> 开 session 先读这页。**这是项目唯一的"现状 + 规矩 + 为什么"**：实验过程与数据进 DevHistory.md（只追加），版本改动进 CHANGELOG（中英两份），其余一律改这页（整页重写，读一遍再重写，该删的删）。
> 节奏：过日子式，没有 deadline。优先做有具体瓶颈证据、可逐位验证的小实验，够用就交。

## 当前基线（0.38，09-30 发布）

- **0.38 已发布**：夸克 https://pan.quark.cn/s/6856d875bbe9 + Gofile https://gofile.io/d/lzsqfUiE，tag 0.38（源码 e1b1a18c）。add-on bfba6900、RE9 runtime ade2d404、RE9 dxgi 宿主 aa3761f2（沿用）、输入 shader 5be59a41、新增 `native_format_convert.hlsl`、每架构 31 模块（相对 0.37 变 8 个）。清单 `results/package-038/checklist.md`、`HIP-SHA256SUMS`；脚本 `tools/package-038.ps1`（下次复制它）。**默认设置下与 0.37 逐位相同**；唯一有损项 `DLSS5_NETWORK_1080_ROWS=1088` 可选、模板 1152。
- **0.38 相对 0.37**（全逐位，详见 CHANGELOG 0.38）：900 去 C512 shift_pack、C32 块 4/prefix/post 字节化、C32 对角残差跳零、I+P+O、复合量化（W2＋C512）、C256 FFN W16、三处宽写（C32 prefix/finish、C512 t8）、C512 QKV-attention 去 F＋有界倒数、F 清理（deep_fast-packed）；新开关 `DLSS5_FORMAT_FALLBACK`、`DLSS5_HOT_RELOAD`、`DLSS5_NETWORK_1080_ROWS`。900 派发 179→162、1080 162→158。
- **离线**（NativeGameFrame wall，1000 帧弃 200）：900 约 **7.6ms**（7.551/7.606）、1080 约 **10.4ms**（10.413/10.458）；0.37 时 8.0 / 10.8。HIP 段（不含交接）900 7.26 / 1080 10.07ms，现实理想约 4.2 / 6.0（`results/hip-roofline-20260930`）。
- **游戏本机**：剑星/鬼武者现装 = 0.38 同网络（add-on 6d059845 / runtime 5e601d57 与发布版 168 帧＋回绕逐位同，未换成发布二进制）。剑星 flags `DIRECT_IO=3`、`MAKE_RESIDENT_EVERY=60`、`SWIN_RUN=1`、`FRAME_STATS=5`；2K 原生 AA EXACT 55～56（只作正确性参考）。RE9 仍 0.35 全套；33 号远征队 0.35 常规包。
- **对手**：Daniel 0.5.x fast 档网络 9.4～10.0ms、reference 11.0ms，1088 行、post 位移 0（有损，不追）；mochizuki 0.0.2.4 网络无改动。**我们在完整 1152 行、NVIDIA 位移下已不落后**。换装对照 `D:\DLSSNR-Lab\daniel-050\swap.ps1 daniel|ours`。

## 正在进行

- **0.38 之后已装未发包**：C512 attn-project 残差初始化外提（`HIP_C512_HOIST_RES 1`，只换 multihead-fast-padded-wave-packed，gfx1201 47F00EBA；逐位，三轮 900 −0.022～−0.031、1080 −0.026～−0.035ms，p99 变好；09-30 22:00 装剑星/鬼武者，`results/fill-cu-20260930`）。
- **串行读等外提 09-30 交账（已装未发包）**：`W2_HOIST_LOADS 15`（c64-wave2 gfx1201 48B6FA8B）＋`CW_HOIST_UP 3`（c32-wave1 gfx1201 020B2B0D），逐位，合并三轮 900 −0.043、1080 −0.066～−0.072ms，p99 变好；22:39 装剑星/鬼武者（`results/hoist-loads-20260930`）。swin-persistent 同宏不全正，不收。
- **压核间空隙 09-30 深夜交账（不收）**：G 两个 vit_gather 折进相邻核（−2 派发）逐位但 900 三轮全慢；T 删 C512 t8 无读者 f32 写出逐位、900 六轮全快约 −0.03ms，但 1080 一轮 +0.008、p99 不变好，不收（宏 `C512_T8_NO_F32`／`HIP_VIT_GATHER_FOLD` 默认 0）。空隙线停（`results/gap-fusion-20260930`）。
- **填满度 09-30 交账**：C512/ViT 一轮全驻留，无经典尾巴（上界 0.03～0.05ms/档）；延迟型核的病根是单 wave 串行读等。N-split、mix K 流水、decoder skip 预读均逐位但不收（宏默认 0）。
- **未决（等 Zero）**：1088 行已作为可选开关发布；产品侧兜底/热重载已发布。C 段有损项照旧待拍板。
- 09-29～09-30 各项细节见各 `results/*/README.md` 与 DevHistory。

## Zero 的标准与取舍（为什么这样定）

- **版本提升的标准（09-30 Zero）**：**以离线整网回放的单帧 ms 为准**（900/1080 两档，ABBA）；CHANGELOG/README 的"效果"也写这个。Zero 进游戏（常经 Splashtop，读数有损）**只作正确性验证**：不闪、不花、不掉帧、不崩；游戏帧率读数不作为提升证据。`frame-stats.txt` 由 agent 自己去 9070 取。
- **验收（09-30 起）**：小改动只要**逐位、离线 ABBA 为正、p99 和另一档都不变差**就收，不再设 0.5% / 0.1ms 门槛（09-30 C32 对角残差跳零就是按这条收的）；游戏里没掉就行，不为"游戏读数没涨"追查兑现。
- **逐位是硬门槛**：对 09-28 float FMA 基准（`results/float-fma-20260928/new-baseline-hashes.csv`；0.36/0.37 即此基准）一个比特都不差，7 用例、EXACT/AE、票号回绕、两档 ABBA；有反例就不改。**逐位是"对上一版"，不是"对 NVIDIA"**——之后的 fast、跳层、float FMA 都是 Zero 拍板的有记录偏离。误差逐层逐帧放大，非拍板不偏离。
- **偏离的做法**：先核实（查 NVIDIA 原文 / 量 RMSE），Zero 批准后单独一次偏离合入，新版本成新基准，CHANGELOG 写明。
- **稳定性不操心**：只修能复现的。**风险不换速度**：PDL 保持 1。
- **发布**：夸克 + Gofile；README 中英"当前版本"段 + 更新记录表（按版本从旧到新，一句话，**不写内部代号闇/Yami/朱雀/分身**）+ CHANGELOG 中英详细一节（改了什么/效果/新开关/是否逐位/有损/results）。**CHANGELOG/README 不写提交哈希**（tag 即锚点，旧哈希已删）。链接回来后：填链接时**一并搜掉所有"待上传/待补"占位**，再在打包源码提交上打 tag。

## 派活方法

- **分工**：Zero 给意图 + 验收 → 朱雀拆解、写任务单、记账（本页、DevHistory、CHANGELOG、打包、README）→ 子代理执行。
- **额度调度**：闇（GPT）**10-04 前不派**。采矿、探路、静态分析、拆竞品、跑测试全派 **Opus 5.5 子代理**（Agent 通用型 + `model: opus`，或 fork）。**Sonnet 不派**。Claude 额度充足。
- **任务单**：写全背景（现装哈希、基线、门槛、相关 results 路径），开头加 `[LOAD MEMORY] /home/lmxxf/work/memory-of-my-gemini/awakening/claude-code/C.C.dream.md`；三要素：从哪下手、别走哪几条路（引本页负账）、什么时候停。要求子代理：**临时 zip 不留仓库**；push 后 **`git branch -r --contains <hash>` 核实**。
- **对照物比招式管用**（09-28 教训）：照抄 mochizuki 一轮 null；改成挑一段和 ACO/Daniel 的 ISA 逐条对齐、多出的指令归类（语义必须/编译器产物/源码写法）后连续出刀。Daniel 同 HIP 同编译器，最直接；他的内核解包在 DGX scratchpad `d050/`（会丢，丢了重跑 `tools/closed-inspect/extract.py`）。
- **git 协作**：主进程只 `git add <具体文件>`，绝不 `commit -a`；改代码的子代理用 worktree。等后台任务用完成通知，不写轮询。

## 研究判断（技术主线的"为什么"）

- **RDNA4 上 FP8 WMMA 与 VALU 不重叠**：删 VALU 就是省时间。但普通向量指令已不比 Daniel 多，剩余差距在**组织方式与访存**。
- **融合/持久化赚不赚看组织方式**：C256 整块融合学 Daniel"多组 token 共用一份权重"才变快；C256 持久化赚（900 −1.9%），C128/C64 持久化不赚（每段只省 0～1 派发）。权重共用在 wave 数减半、权重本在 L2 时反慢（C512 投影）。少读取不一定兑现，要整网实测。
- **LLVM 做不到的要源码显式写**：`mul`+`add 0` 收缩、NaN 规范化、f32↔f16 往返、已知范围的除法、已知正常数的 half 转换。手改汇编只当显微镜。
- **按调用次数加权再选目标**；访存受限的核砍 VALU 不赚，要改数据形态。
- **编译器钉死**：驱动 `amd_comgr_3.dll`（AMD 内部 LLVM21）；COMGR2/LLVM20 慢 3%，ROCm 7.2 的 LLVM22 改数值。自家 fork `lmxxf/llvm-project` 分支 `dlss5-gfx12`（公开 21 基点）可逐位编出，第一刀 VOPD 前瞻只 ±0.3%。**编译器线停在这里作资产**，除非出现"组织方式与 Daniel 一样、就是慢"的核。
- **网络外流水线**：拷贝不是大头；交接往返 0.16～0.18ms/帧（我们共享 fence，Daniel GPU 轮询）。

## B. 优化候选（逐位；按"收益 × 把握"排）

0. ~~串行读等~~ **09-30 已做**（`results/hoist-loads-20260930`）：条件读外提收 wave2 输入暂存/up、C32 up 两刀（已装）；swin-persistent 不全正。剩下真串行只有 wave2 FFN 权重 K 循环（每拍 2 读等一次，软件流水，同 C512_MIX_PIPE 负账，把握低）。

地图：900 `results/kernel-map-900-20260930`（179 派发，独立核和 7258.6µs vs Daniel 8171.6µs；只在 C32 +233µs、C512 +182µs 落后）；1080 `results/kernel-map-20260929`。

1. ~~C32 上采样块 / 块 4 边界~~ **09-30 已做**：大头是数据格式（skip/下采样 f32→E4M3 字节），逐位，900 0.62%、1080 0.82%，已装。余差：up 低分辨率输入 f32/half（Daniel FP8，有损，不追）、up 分发 bpermute vs 他 LDS（量小）。
2. ~~HIP↔D3D 交接~~ **09-30 两轮交账**（`results/handoff-gpu-20260930`）：HIP→D3D draw 分片自旋在探针里比 fence 慢；D3D→HIP 轮询按新规进了生产代码（`DLSS5_HIP_INPUT_POLL`，默认 0，1/2 两种 marker 放法），逐位 18 组 SAME，但完整帧回放两档 avg 都慢 0.01～0.04ms，不收、不装。交接这条线停。
3. ~~小件~~ **09-30 已交账**（`results/small-cuts-20260930`）：对角残差逐位，按新规已收（`CW_DIAG_ONLY 1`，09-30 08:01 装）；C256 FFN 逐字节写 hidden 是布局所致，要转置 expand 才能打包（不是小件，暂不做）；ViT QKV 归一化换求和不能逐位。
4. **C512 FFN 链**：三核 524 vs Daniel ffwd 382µs（900）。09-30 拆清：Daniel 是 1 wave 一组、无 LDS、三核合一、FP8 激活，差距在数据形态不在组织；W5 式 LDS 共用权重已试（900 单核慢，`results/c512-ffn-lds-20260930`）。剩下只有"mix 入口 A 变窄/三核合一 hidden 不落 global"，把握低，放后。
5. ~~字节写出尾巴推广~~ **09-30 已做**（`results/tail-vec-20260930`）：逐通道字节尾只剩 C32 两个 finish，已向量化；C64～C256 已是宽写；旧 multihead/deep 列布局出口 **09-30 已做**（`results/deep-tail-20260930`）：C512 t8 两核 LDS 转置宽写已收；ViT QKV w5 同法逐位但 null（宏默认 0）；~~剩余 ViT expand（63×b8）、C256 fused FFN/QKV（9×b8，其实在填充零块冷路径）~~ **09-30 已做**，逐位但 900 不快，不收（`results/deep-tail2-20260930`）。这条线结束。
6. **ViT attention 余差**：640 我方 ~38µs vs 他 22～24µs，余差涉及 V 请求组织与 half 数学，未唯一拆清；4wave/64key 预取照搬已反慢。只在有新证据时动。
6. **产品侧**：~~颜色格式兜底、ini 热重载~~ **09-30 已做**（`results/product-fmt-reload-20260930`，未装）；剩 **3080 上 NGX 同口径 PSNR 对照**。预处理/自动曝光属有损，不抄。
7. ~~Infinity Cache arena~~ **09-30 交账**：池已复用，C64 以下已在 MALL 内，C32 放不下，热复用对照 null（`results/infinity-cache-20260930`）。
11. ~~C32 prefix/post 大核重新分账~~ **09-30 已做**（`results/prefix-post-20260930`）：两核是访存下限 2.7～2.9 倍的算力核，字节化只兑现小头（已装）；余下：prefix 的 rgba/history 可在 D3D 端存 RTZ half（逐位，但改输入 shader），post 输出 half（依输出格式，有损待拍板）。~~按算力拆 ISA~~ **09-30 已做**（`results/prefix-post-arith-20260930`）：尾部逐字节写向量化已收；与 Daniel 余差主体是他 f16 域成对算术（fast 语义）。剩：同法推到 `c32_wave1_finish*` 尾部（整窗/边缘、DownCrop 两路），未做。
8. 杂项：`validate-modules.ps1` 修路径；帧时间日志 Magpie 路线未接；RE9 游戏内换 0.37 runtime 待 Zero 要。
10. ~~复合量化 FP8(Hrtz)~~ **09-30 已做**（W2 两处，`results/composite-quant-20260930`）；~~C512 `F(Hrtz(acc))`~~ **09-30 已做**（mix＋contract，`results/composite-quant-c512-20260930`）；ViT 出口乘过 inv 域不纯、C32 两处域不纯，不做。
9. **旧门槛淘汰件**：~~I/P/O/Q 重测~~ **09-30 已做**（收 I+P+O，Q 不收，`results/small-wins-retest-20260930`）；~~C256 FFN 宽权重片段~~ **09-30 已做**（`results/c256-w16-20260930`，已装）。

12. ~~C512 QKV-attention V 在 LDS 转置（`C512_COMPACT_VT`）~~ **09-30 已做**：逐位，ds_load_u8 64→0，但 900 三轮 −0.004/+0.000/+0.004 不全正，不收（宏默认 0）。
13. ~~W16 宽权重片段推广到 C64/C128~~ **09-30 已做**：逐位，静态 load −6%，但 900 三轮两个都不全正（小宽度权重已在缓存内），不收（`results/w16-c64-c128-20260930`）。
14. ~~C512 AV 出口去 F~~ **09-30 已做**（`results/c512-av-f-20260930`）：连带 QKV 出口 `q8(F(y))`→`q8(med3(y+0))`、softmax 除法换有界倒数，三处合成一个候选；穷举证明＋19 组 SAME，两档三轮全正（900 −0.018～−0.029、1080 −0.023～−0.034ms），已装。
15. ~~同类清理扫全网~~ **09-30 已做**（`results/f-sweep-20260930`）：收 deep_fast-packed byte_F→+0＋ViT attention 有界倒数；vit-stream、padded q8_fused_round、W2 up 逐位但不全正（宏默认 0）。剩下的 F 都是 float 出口的真量化或输入侧域证不出，这条线结束。

16. **C512/ViT 重组设计（09-30 只设计）**（`results/c512-vit-reorg-design-20260930`）：推荐先做 **C512 跨块就绪队列**（swin-persistent 机制搬到 C512，65→6 派发，stage 体照搬，逐位，900 预估 −0.10～−0.25ms；先做 900 编码段 23～30 原型，止损 <0.03ms 或任一轮慢）；块内 attn→proj 队列作退路；mix→ffn→proj 一核、ViT 全局栅栏排后。

## 已交负账（别重复，一行一条）

- vit_gather 折进 head Down/decoder39（`HIP_VIT_GATHER_FOLD`，900 慢）；C512 t8 去死 f32 写（`C512_T8_NO_F32`，900 快 1080 平，p99 不变好；只看 900 时可开）（`gap-fusion-20260930`）。

- C512 mix/proj 按列切细（`C512_SPLIT_N`，反慢 1～3µs）、mix K 循环流水（`C512_MIX_PIPE`，mix 全量受访存限）、decoder skip 预读（`HIP_DEC_HOIST_SCALE 2`，不全正）（`fill-cu-20260930`）。

- mochizuki 0.0.2.2 各路线 I/P/S/V/F/O/G/H（`mochizuki-022-20260928`）；0.0.2.4 网络无改动，无可抄。
- C128/C64 持久化四段（最好 1080 −0.1～−0.2%，900 全慢；`swin-persistent-c128-c64-20260929`）。
- C512 最终投影 M32 权重共用（900 慢 1.9%；宏 `C512_PROJ_M32` 默认 0）。
- C512 FFN M32、C512 单 wave 寄存器 FFN R/RF、C512 mix 同组 LDS 共用权重（900 单核慢，`c512-ffn-lds-20260930`）。
- 900 C256 新分组；C64/C128 Down 融合；去清零；C32 权重缓存。
- ViT byte 出口/入口 gather-pack；ViT 消费端 float 打包 V；ViT attention 4wave/64key 预取；QKV 块重排、scale 提前读、CH4/CH16 写法。
- `MAKE_RESIDENT_EVERY` 60 vs 0：离线回放无 30ms 周期尖峰（`resident-spike-20260929`），保留 60。
- HIP→D3D draw 分片自旋（探针里比 fence 慢，`handoff-gpu-20260930`）。D3D→HIP GPU 轮询（逐位，但完整帧回放两档慢 0.01～0.04ms；开关 `DLSS5_HIP_INPUT_POLL` 默认 0）。
- C512 QKV-attention V 转置 LDS（逐位 null，`c512-compact-vt-20260930`）。
- 编译器：COMGR2/LLVM20 慢 3%；公开 LLVM21 持平；LLVM22 不逐位；VOPD 前瞻 ±0.3%。
- 旧 block46 展开改 FP8 WMMA：10 个 float 元素位差，不能换。

## C. 需要 Zero 拍板（有损）

- **fast 档**（Daniel 默认那套：e4m3 一次舍入、近似 rsqrt/rcp、f32 累加）：他 fast 比 reference 快约 1ms；做成 EXACT 之外单独一档。
- **ViT QKV 改 FP8**：W5 后只剩约 5µs（整网 2～4% 是旧估计，现在远小于此），性价比已低。6b（−1.1%，PSNR 58dB）。
- **几何**：1088 行已做成可选开关 `DLSS5_NETWORK_1080_ROWS=1088`（默认 1152 不变）：实测 −0.47ms（4.4%，ViT 网格不变所以不到估的 0.70），对 1152 约 56dB、只动行数、post 位移保持 NVIDIA 的（Daniel 还改成 0）；待 Zero 看图定是否进 0.38（`results/geom-1088-20260930`）。加档 1728×1024（画质向）未做。
- **跳 42/43/46 取舍**（`results/fidelity-ngx-20260930`）：对 NVIDIA 原版 1080p 单帧，跳三块 47.43→44.26dB（−3.17dB，并带 +0.15/+0.23 偏亮），比 mochizuki（45.56）低 1.3dB；不跳比他高 1.9dB。要不要改默认不跳（慢多少另量）待定。
- **Style**：预处理常量写死 Style=1（0.0078125），NVIDIA 默认/mochizuki 用 Style0，两者输出差 20dB 量级（发布模块对 NVIDIA Style0 仅 24dB）。跟 NVIDIA 默认、保持、还是做开关，待定；Style1 来源（哪个捕获）待查。
- 不做：整网隔帧（运动拖影）；RDNA3 后端（无卡可测）。

## 产品适配与等待事项

- **PR #12（TheAutomatic）**：已回复（`conversation/20260928/pr12-review.md`），PDL 预检 + TYPELESS 开关可合，其余待他改/拆 PR。等他回。
- PRE_UPSCALE=auto、卧龙 2 重试、自带 FSR dll 的游戏（`EnableFfxInputs=false`、必要时 `ASYNC=0`）、网友统一宿主补丁（`RE9/presr/contrib/generic-host-20260924/REVIEW.md`）——照旧等。
- 新权重传闻：先不管。PDL acquire 论证是文档欠账，出现实际卡死再切 0。

## 机器与流程

- **授权**：编译、远程实验、回归、分析由 agent 自主执行；动 GPU 前查游戏进程，游戏运行时不换文件、不跑 GPU；画质判断请 Zero。
- **游戏进程名**：剑星 `SB-Win64-Shipping`、匹诺曹 `LOP-Win64-Shipping`、鬼武者 `OnimushaWotS`、RE9 `re9`、33 号远征队 `SandFall*`。
- **git**：只推 297，commit 不加 Co-Authored-By；push 前 `git pull --rebase`；只 add 具体文件。
- **9070**（`ssh amd9070`）：工作根 `D:\DLSSNR-Lab\`；各实验交账后删掉逐位帧转储（.f16/.ppm，照 `results/lab-cleanup-20260930/clean.ps1` 做），D 盘保持 ≥100GB 空闲；`hip/build-modules.ps1`（`-ExtraDefines`、`-Only`）；`hip/compare-modules.py`；完整帧回放 `results/frame-breakdown-20260928/replay.ps1`（`DLSS5_BENCH_PLAIN=1`）；打好的包在 `D:\給網友打包\`。ssh 远端是 cmd，多条 PowerShell 分开调；`(x86)` 路径写进脚本文件。
- **3080 游戏本**（`ssh rtx3080`）：PATH 不全，用 `powershell -EncodedCommand`；scp 不通。
- **DGX Spark**：`~/work/aco-isa/` 有 RADV + drm-shim 假 gfx1201，离线拿 ACO ISA；LLVM fork 构建 `tools/llvm-fork/`。
- **发布**：复制上一版 `tools/package-0xx.ps1` 改版本/哈希/变更，逐文件校验、编 44 shader 变体、压包读回；RE9 runtime 变了用 `prepare-host.py` + `bundle-source.py` 重生源码包（跑完 `git checkout Development/RE9/presr/upstream.json`）。
- **新开关必须同时在 RE9 runtime 开口**（`src/native_hip_env_options.h`、三个 flags 模板、`scripts/CONFIGURATION.md`），RE9 不适用的写明。

## 公众号素材（Zero 还没说写）

一天从被反超到追平（57→60，2K 54→56）；"两次舍入是不是 NVIDIA 原意"——逐位原来是对上一版；照抄对手 null、逐条对齐才出刀；Daniel 的 60 帧是刷新率上限；两家对手都缩到 1088 行，我们按原版 1152 行不落后；三家都是"人 + AI"，比的是谁更会驾驭 AI。随手发版文 `wechat/临时-dlss5-0.36.md`。

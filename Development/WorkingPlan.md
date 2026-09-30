# 当前工作计划（覆盖式，不续写；最后更新 2026-09-30，朱雀）

> 开 session 先读这页。**这是项目唯一的"现状 + 规矩 + 为什么"**：实验过程与数据进 DevHistory.md（只追加），版本改动进 CHANGELOG（中英两份），其余一律改这页（整页重写，读一遍再重写，该删的删）。
> 节奏：过日子式，没有 deadline。优先做有具体瓶颈证据、可逐位验证的小实验，够用就交。

## 当前基线（0.37，09-29 发布）

- **0.37 已发布**：夸克 https://pan.quark.cn/s/7dbfdc6425fd 、Gofile https://gofile.io/d/onqeAHST ，tag 0.37。add-on b77bbc3c、RE9 runtime 2c103f6e、RE9 dxgi 宿主 aa3761f2（沿用）、输入 shader 5be59a41、每架构 31 模块。清单 `results/package-037/checklist.md`、`HIP-SHA256SUMS`；脚本 `tools/package-037.ps1`（下次复制它）。**与 0.36 逐位相同。**
- **0.37 相对 0.36**（全逐位）：深层紧凑、head 分组融合、C256 跨层持久化队列（`DLSS5_HIP_SWIN_RUN`，源码默认 0、三个模板写 1；约 100ms 超时 GPU 重算并禁用本实例）、ViT attention 新核、ViT QKV 五 wave 共享权重。900 派发 198→179、1080 182→162。常规 OptiScaler 包补 `ReShade.ini`；RE9 源码包补收 `hip/*.inc`。
- **0.37 之后已装未发包**：900 档 C512 去 `mh_shift_pack`（宿主按 16 token 补齐分配，`HIP_C512_PAD16` 默认 1，容量不够自动回落 pack；不改模块）。宿主 **62803606**、RE9 runtime **be828151**。900 省 0.09～0.11ms（1.1～1.4%），1080 不变。`results/shift-pack-900-20260930`。
- **离线**（NativeGameFrame wall，1000 帧弃 200）：900 约 **7.9ms**、1080 约 **10.8ms**（0.36 时 8.5 / 11.2）。
- **游戏本机**：
  - 剑星：2K 原生 AA EXACT **55～56**（1080 档，shift_pack 不影响；0.36 为 54）。add-on 62803606 + 31 模块，flags `DIRECT_IO=3`（含 FSR 输出直交，仅剑星现场）、`MAKE_RESIDENT_EVERY=60`、`SWIN_RUN=1`、`FRAME_STATS=5`。最近备份 `D:\DLSSNR-Lab\hip-backend\shift-pack-900-20260930\backups\stellar-20260930-004205`。
  - 鬼武者：runtime be828151 + 模块与剑星对齐；**2K 质量（900 档）中画质稳定 60，GPU 90～95%、从未满载**。备份 `D:\DLSSNR-Lab\onimusha-backups\20260930-004205-shiftpack`。
  - RE9：仍 0.35 全套（新 runtime 只做过包内冒烟）；33 号远征队 0.35 常规包；匹诺曹旧版（贴 60 不作对比）。
- **对手**：Daniel 0.5.0/0.5.1 默认 fast 档（f32 累加、e4m3 一次舍入、近似 rsqrt/rcp）网络 9.4～10.0ms，reference 档 11.0ms；他 1080 只算 1088 行、post 位移 0（有损，不追）。mochizuki 0.0.2.4 相对 0.0.2.2 **网络零改动**，只加产品侧（`results/mochizuki-024-20260930`）；他 1080 也是 1088 行，Windows 与 Linux 自报差 48.6dB。**我们在完整 1152 行、NVIDIA 位移下已不落后。** 换装对照 `D:\DLSSNR-Lab\daniel-050\swap.ps1 daniel|ours`，看 `dlssnr_on_amd.log` 的 network 均值。

## 正在进行

- **下一版（0.38）待打包**：① 900 去 shift_pack（`results/shift-pack-900-20260930`）；② C32 块 4 skip/下采样存 E4M3 字节（`results/c32-align-20260930`，逐位，900 −0.05ms 0.62%、1080 −0.09ms 0.82%，改 c32-wave1＋multihead-fast-padded-wave-packed 两模块）。③ C32 对角残差跳零 `CW_DIAG_ONLY 1`（Zero 批准，逐位，1080 约 −0.04ms；09-30 08:01 已装）。④ 旧门槛淘汰件重测：I+P+O（c32 入口/prefix 去 half 往返＋C512 mix/ViT contract 占用上限，逐位，900 −0.03ms、1080 −0.02～−0.03ms，p99 不变差；Q post 内部窗口不收；09-30 10:16 已装，只换 c32-wave1/c512-m32-deep/vit-stream，`results/small-wins-retest-20260930`）。⑤ 复合量化掩码 `W2_Q8_MASK 1`（FP8(Hrtz(x))→FP8(bits&0xffffe000)，2³² 穷举＋逐位，900 −0.005～−0.016ms、1080 −0.003～−0.022ms，p99 三轮合并不差；09-30 10:41 已装，只换 c64-wave2/swin-persistent，`results/composite-quant-20260930`）。⑥ C256 FFN 权重 16 字节片段（宿主 `HIP_C256_FFN_W16`＋核 `W2_FFN_W16` 新增 `_w16` 导出，缺模块/旧宿主都回旧布局；逐位，三轮 900 −0.011～−0.025、1080 −0.030～+0.003ms，p99 合并不差；09-30 11:25 已装，`results/c256-w16-20260930`）。⑦ C512 `F(Hrtz)`→`F(mask)`（`C512_F_MASK 1`，c512-m32-deep＋deep_fast-packed；2³² 穷举＋域证明，mix 域依赖权重最小位 2⁻⁹；逐位，三轮两档全正 −0.006～−0.029ms；09-30 11:37 已装，`results/composite-quant-c512-20260930`）。⑧ C32 prefix down / block69 main 存 E4M3 字节（`CW_PREPOST_BYTE 1`＋宿主回退，逐位，三轮 900 −0.009～−0.024、1080 −0.017～−0.025ms；09-30 12:10 已装，`results/prefix-post-20260930`）。⑨ C32 prefix 字节尾向量化（`CW_PREFIX_TAIL_VEC 1`，只换 c32-wave1，宿主不变；逐位，三轮 900 −0.040～−0.046、1080 −0.065～−0.074ms，p99 全变好；09-30 12:31 已装，c32-wave1 3f9cdd24/00b1d536，`results/prefix-post-arith-20260930`）。⑩ C32 finish 字节尾向量化（`CW_FINISH_TAIL_VEC 1`，finish_b8/finish_dcrop_b8d，只换 c32-wave1；逐位，三轮 900 −0.038～−0.046、1080 −0.043～−0.055ms，p99 全变好；09-30 12:45 已装，c32-wave1 8e47b814/fd8fed73，`results/tail-vec-20260930`）。⑪ C512 t8 字节副本 LDS 转置宽写（`C512_T8_TAIL_VEC 1`，split_ffn_fused_fp8_t8＋split_projection_frag，只换 deep_fast-packed；逐位，三轮 900 −0.008～−0.009、1080 −0.005～−0.028ms，合并 p99 变好；09-30 13:09 已装，deep_fast-packed 7ffaa65f/ebc7df69，`results/deep-tail-20260930`）。现装宿主 **6d059845** / RE9 runtime **5e601d57**，剑星、鬼武者已装。**打包注意**：add-on/runtime 须从含本补丁的源码重编（6d059845 是 7ca25c98＋W16＋prefix-post 补丁编的，未含其后 1088/input-poll/产品侧提交）。Zero 定何时发。
- **1088 行紧凑几何（可选档）09-30 交账**：`DLSS5_NETWORK_1080_ROWS=1088`，默认 1152 逐位；开时 1080 −0.47～0.48ms（4.4%），对 1152 全帧约 56dB、底边 32 行 52.5dB 略差。产物在 `D:\DLSSNR-Lab\geom1088-20260930\`，未装；**等 Zero 看 ppm 决定是否作可选档进 0.38**（`results/geom-1088-20260930`）。
- **产品侧 09-30 交账（未装机，等 Zero 定随哪刀装/打包）**：颜色格式兜底 `DLSS5_FORMAT_FALLBACK=1`（R9G9B9E5/B8G8R8X8/R10G10B10A2/R32G32B32(A32)/SNORM/565 等转 RGBA16F，原格式逐位）＋热重载 `DLSS5_HOT_RELOAD=1`（STRENGTH/NOTICE/SHOW_FPS）。add-on 8b729f22、RE9 runtime 99c8ead9，产物 `D:\DLSSNR-Lab\product-fmt-20260930\`；**打包须新增 `native_format_convert.hlsl`**。`results/product-fmt-reload-20260930`。
- Infinity Cache / arena 09-30 交账：宿主池已按生命周期复用，C32 单派发 141/203MB 超过 64MB MALL，热复用对照逐位但 900 慢 0.01ms，不收（`results/infinity-cache-20260930`）。
- 9070 D 盘清理 09-30 交账：删掉已交账实验的逐位帧转储 486.7GB，D 盘约 527GiB 空闲，基准自检 168/168（`results/lab-cleanup-20260930`）。剩余两个字节出口 09-30 交账，不收（`results/deep-tail2-20260930`）。
- **逐核地图 v3 09-30 交账**（`results/kernel-map-v3-20260930`）：现装模块两档独立核和 900 6895µs、1080 约 9762µs，整网回放 7.615 / 10.436ms。候选写入 B 段 12～14；第一个（C512 V 转置 `C512_COMPACT_VT`）逐位但不全正，不收，未装（`results/c512-compact-vt-20260930`）。
- W16 推广到 C64/C128 09-30 交账：逐位（含回退与 origin/main 现路径 19 组 SAME），但 900 三轮 C64 +0.005/−0.010/+0.003、C128 −0.016/+0.004/−0.003 不全正，两个都不收、未装（宏 `W2_FFN_W16_SMALL` 默认 0，`results/w16-c64-c128-20260930`）。
- C512 QKV-attention 去 F＋有界倒数 09-30 交账：收，已装 c512-m32-mh 0F28A38C（`results/c512-av-f-20260930`）。
- F 清理扫全网 09-30 交账：4 组全证明、全逐位；只收 deep_fast-packed（`HIP_BYTE_F_ADD0`＋`HIP_VIT_ATTN_RCP`，900 −0.014～−0.038、1080 −0.011～−0.028ms），已装 EEC7D4A6；vit-stream/padded-wave-packed/W2 up 不全正，不收（`results/f-sweep-20260930`）。
- **对 NVIDIA 原版同口径画质 09-30 交账**（`results/fidelity-ngx-20260930`，只量未改）：复算 mochizuki 单帧与公布值一致；1080p Style0 下全 71 块 47.43dB、发布跳块 44.26dB（他 45.56）；运动序列无公开 NVIDIA 输出未测；1440/4K 无同几何档。发现发布网络写死 Style=1（见 C 段）。
- 交接 GPU 同步 09-30 交账（HIP→D3D 分片自旋反慢，未装）。C512 FFN W5 式 LDS 共用权重 09-30 交账（900 单核慢，停，`results/c512-ffn-lds-20260930`）。其余无在跑任务。09-29～09-30 已完成项细节见各 `results/*/README.md` 与 DevHistory。

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

## 已交负账（别重复，一行一条）

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

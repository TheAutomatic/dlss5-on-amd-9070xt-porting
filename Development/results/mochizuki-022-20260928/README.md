# mochizuki 0.0.2.2 对照：九组逐位实验，无达标组合

**结论：不合生产、不装机、不发包。** 单项、I+P+O组合以及四wave同组的直接对照，均未稳定达到任一档整网≥0.5%。按任务单交完整对照账，不继续堆候选。

基线7fcad1e：剑星内核仍第五刀；add-on已为帧时间日志版c38bcdd4。本轮只做HIP/分派实验，不改src/。实验根 `D:\DLSSNR-Lab\hip-backend\mochizuki-022`。30生产模块gfx1201重编的代码/metadata与现场基线30/30相同。目标组合在900或1080至少一档稳定≥0.5%，EXACT/AE都逐位。

## 对照4f62a8a → 228d3a6

源是任务单给的本机clone，revision和文件SHA见upstream-sources.json；pipeline-delta.json逐管线列出增删的宏，避免把include拆文件当算法变化。

| 他改了什么 | 我们对应位置与现状 | 是否可逐位采用 / 本轮动作 |
|---|---|---|
| Windows NR_Q32_DIRECT预处理删除f16中转 | C32输入、FFN/投影残差，C512/ViT H/Hrtz边界 | **不能统一删除**：源码明说f32输入会丢舍入。只删可证明half格点上的重复转换，I/P候选 |
| Windows NR_Q32_STAGE把yh/requantized/widef留f32 | wave_owned_c32.inc里的FFN residual、projection结果与pool | 我们保留半精度舍入合同，已有CW_RTZ_PAIR以half位模式存LDS；不能把未舍入的acc直接留下 |
| 两对量化合成quad，一次MODE写填满DWORD | CW_PACK8/W2_PACK8、短固定MODE段 | 主路线已做。CW固定四转换段；W2旧intrinsic空段仍是已知实现差异，不照抄改变范围/数学的配置 |
| NR_HALF_RTE阻止LLPC将纹理读取折成d16 | prefix输入来自HIP float buffer，不是该GLSL纹理取样路径 | 没有同一种texture折叠问题；不搬该补丁 |
| NR_TCHAIN按tile替代dispatch barrier | 现有PDL只跨C64～C256 | 上游**Linux19条管线启用，Windows0条**。新S/V实验保留M32/字节接口，分别只扩一段短链，含回绕与AE跳过处理 |
| C512 gemmprojc独立管线、转置32×32 wave tile | 我们已有split_projection_frag和attention_project独立核，16×64 wave tile、f32残差+字节输出 | 独立派发本身已有；数据合同/寄存器方向不同，不重做已关转置布局，选供数/驻留安排验证 |
| occ_pad以空LDS限制驻留 | C512 mix、ViT contract当前LDS0 | 可不改数学；O候选各加4KiB LDS，对齐单wave组下约4wave/SIMD上限，非照搬4wave组的字节数 |
| ffwd3 group-major与GEMM编号重排 | C512 mix/QKV按token tile优先，重复取不同列权重 | G候选改为权重列组优先，相同group总数和每输出K顺序；不同于上轮增加group数量 |
| C256上下采样折入所有尺寸的persistent run | 已有C32尾部融合、PoolProject；C256 persistent路线已关 | 拓扑不相同，不能只挪分辨率条件。遵守已关约束，不重做持久化 |
| ViT分母留lane、恢复P的key顺序 | 我们denominator用固定顺序FP16 WMMA累加 | 上游是packed-half局部加法树，和本机WMMA树不相同；不能只搬shuffle/packed-half加法并宣称逐位，本轮不改归约 |

上游README明确Windows7.79ms是离线数，未实机验证，和Linux输出相差48.6dB；“f32≥native precision”也不等于保留我们的舍入。此版本合并了多个改动，不能把整个17%当成一项已经证明可移植的收益。

## 往返普查

30模块共990个kernel导出，当前EXACT整网214次派发实际用40个（900/1080目标配置联合）；其他导出在此配置下权重为0，720另作正确性验证。conversion-static.json保存全表，conversion-active.json带CFG/def-use站点与真实900/1080 group数。导出按.amdhsa_kernel元数据筛选，剔除了90个编译标记/元数据伪标签；识别器覆盖_e32/_e64别名、寄存器搬运/移位，保守地只在同基本块连接转换；跨控制流/LDS需结合源码，不把匹配不到当作不存在。

**计数口径**：conversion-dispatch-weighted.json按“静态转换站点×实际派发wave”加权，不是循环展开后的执行指令数。它用于全网筛选。候选I/P另外给出qt=4展开后的删除量；分支按上界。禁止把这些条数当GPU周期或内存带宽。

| 档位 | 加权RNE收窄站点 | 加权RTZ打包站点 | 加权拓宽站点 | 已证明I+P可删占该口径比例 |
|---|---:|---:|---:|---:|
| 900 | 13,394,884 | 12,835,619 | 27,052,339 | 2.812% |
| 1080 | 18,944,760 | 17,875,315 | 38,108,851 | 2.876% |

这里的2.8%是本轮已证明部分，不宣称其他位置全部不可优化。大量H/Hrtz是实际算术边界：FFN收缩/残差、pool的四个舍入、C512 mix/投影、ViT residual与最终投影、decoder合并。C32 residual的“RTZ→LDS half→float”已经使用CW_RTZ_PAIR直接存half位模式；C512/ViT QKV的LDS raw是f32，不是隐蔽的half往返；ViT attention的LDS half来自exp位映射并直接喂WMMA，是算法输入。没有因为正则命中cvts就删除它们。

`rounding-proof.py`给出63488个有限half编码的往返恒等检查，以及反例：f32 bits=0x3f880001（1.062500119…），直接FP8=0x39，经half先变1.0625再FP8=0x38。**目标格式更粗不能保证前一道舍入冗余。**

## 实现与指令账

| 候选 | 具体做法 | 静态普通向量 / 资源变化 |
|---|---|---|
| I | mapped入口由prefix FP8或decoder half提供；post是同核刚得到的Hrtz值，删除再次RNE收窄/拓宽 | mapped 767→747、post1107→1083，VGPR/LDS不变；每核少16收窄+16拓宽，qt4后每wave少128条转换 |
| P | 保留prefix最后一次RTZ的half位模式，shuffle同样的half字，直接装WMMA输入；原颜色/噪声舍入不删 | prefix1304→1290，VGPR129不变；少6收窄+8拓宽，qt4按分支上界少56条转换 |
| S | C512 projection→M32 QKV按16token计数；8列组完成，消费者等两个tile | producer565→569、VGPR83→84；consumer490→494、VGPR155不变；增加标志访问与agent同步 |
| V0 | ViT contract→QKV，每tile16个列组完成后发布，consumer acquire轮询 | contract659→669、VGPR205→206；QKV322→363、96→97；新QKV三处global_inv（含轮询内）。这是后续发现生命周期缺口前的先导版本，不作生产候选 |
| F | ViT按现行PDL方式relaxed轮询、编译器屏障、release发布；保留hidden引用到该段结束 | QKV三处global_inv→0，静态VMEM61→58；VGPR97。正确性/速度结论只用修复生命周期后的F |
| O | C512 mix与ViT contract各加4KiB静态LDS，只作占用上限，合法token域不执行占位分支 | mix VGPR96→102，API64→16组/MP；contract VGPR205不变，API24→16组/MP |
| G | C512 mix/QKV权重列组优先的组间编号，一一映射；不增组、不拆K | mix静态普通向量786→715、VGPR96→95；QKV490→457、VGPR155不变，访存条数不变 |
| H | 正面对照上游真正的“同组共享权重”：mix四wave/128线程一组，每wave算独立32token，整组同64列权重；无LDS/barrier | mix VGPR96→95、LDS0/private0；每wave静态普通向量786→785、WMMA8不变。第一版G仅改组间顺序，不能替代此对照 |
| C | I+P的c32-wave1与O的两模块组合实测 | 不相加单项百分比；三模块组合独立做完整回归/ABBA |

静态表不冒充执行指令数：S/V/F的轮询体只计一次，O含不会执行的占位分支；候选全opcode表、模块/内核名和资源见candidate-isa.json，驱动查询见resources-result.txt。I/P的qt4删除量在census-summary.json单列。

H让112/144个128线程组覆盖900原448/560个wave（70tile末组有16个多派发但提前退出的wave）；1080是160组、640wave。保持完整K序、每输出操作数不变；EXACT/AE每例均记录156次替换，即13核/帧。G的编号映射另有512种几何、528384组坐标对照（group-proof.json），不能把“换编号”算成“工作组翻倍”。

## 计数器的回绕与buffer生命周期

S/V/F的生产者普通派发，消费者any-order，后续attention保留普通屏障；原C64～C256 PDL=1始终同时开启，确实在测叠加，而非关掉原PDL换收益。沿用PdlSlot：即将溢出时排空旧使用者、清零、再等待清零完成。压力构建对新kind用TC_WRAP_LIMIT=64。

ViT AE命中时生产者仍发布计数，消费者跳过等待/计算，所以后一次refresh的目标不会凭空超前。实际trace：S每12帧156次，V/F每12帧96次。S的900/1080历史强制回绕18/19次，V/F各23次；S/F另在AE静止复用下同样触发回绕，输出仍逐位。

第一版relaxed F在720-motion出现逐位反例，旧记录在rejected-F-before-keep，未进入最终统计。源码检查发现：原串行代码在contract之后hidden.reset()，norm=New(...)的best-fit池可能复用仍被并行producer读取的hidden。最终F在此段保留vtc_keep，分配norm后断言没有别名，直到该ViT调用结束才释放。该版重新通过全部回归、历史回绕和AE回绕。它同时改了同步与必要的buffer生存期，**不把V0→F的差额全部归给global_inv**。V0只保留先导测量，未作为可部署版本；C512 S的producer输入在相应局部作用域内本来就保持引用。

本轮没有改现行生产PDL或src。F使用现行relaxed策略只是实验，不能用这份回归冒充一般GPU内存可见性证明；它也未过速度门槛。

## 两档两批整网结果

完整NativeGameFrame回放，PDL=1、VIT_STREAM=3、EXACT计时；每槽1000帧弃前200，ABBA只读首尾，正确性另做逐帧读回。负数为更快。

| 候选 | 900 两批Δms | 1080 两批Δms | 判断 |
|---|---|---|---|
| I 入口half去往返 | +0.0026 / -0.0164 | -0.0014 / -0.0235 | 小于门槛 |
| P prefix half位模式 | +0.0053 / -0.0005 | -0.0161 / -0.0174 | 小于门槛 |
| O 占用上限 | -0.0122 / -0.0130 | -0.0068 / -0.0062 | 小于门槛 |
| C I+P+O组合 | -0.0125 / -0.0270 | -0.0272 / -0.0180 | 小于门槛 |
| G 组间权重优先 | +0.0932 / +0.0741 | +0.1101 / +0.0995 | 变慢，不采用 |
| H 四wave同组 | +0.0426 / +0.0331 | +0.0402 / +0.0447 | 变慢，不采用 |
| S C512短链 | +0.0404 / +0.0321 | +0.0488 / +0.0490 | 变慢，不采用 |
| V V0 ViT强acquire先导 | +0.4592 / +0.4594 | +0.3862 / +0.3781 | 变慢，不采用 |
| F ViT relaxed＋生命周期修复 | +0.0101 / +0.0174 | +0.0142 / +0.0276 | 变慢，不采用 |

组合C的绝对值：900两批9.2539→9.2414、9.3179→9.2909ms（−0.13%/−0.29%）；1080两批12.6134→12.5863、12.6380→12.6200ms（−0.22%/−0.14%）。没有合配方的成熟组合，故不存在“合入后的新帧时”。所有单项绝对值和百分比见summary.json。

九组标准回归共**1512候选帧逐位相同**；756组AE决策逐字段同，每组43复用+41刷新。强制回绕/AE回绕额外120候选帧同；连基线共3264份逐帧hash。不同实验host的基线也逐帧互相匹配。失败的F初版排除。gfx1200只编译，gfx1201实测。

## 本轮判断

1. 17%是上游Windows离线整包差额，包含真实舍入变化和多项配置调整；同属LLVM不等于同前端、同数学、同数据合同。可以借方法，不能照比例承诺收益。
2. 明确可删的输入/prefix往返已经删到源代码并测过，只得到小收益；当前残留大量转换是算法的舍入、操作数格式或half暂存，不是统一可删的垃圾。
3. 两条短tile链没有在现有PDL上取得正收益。agent acquire轮询确实生成额外global_inv；去掉它并修复buffer生命周期后也只是回到基线附近。上游Linux是19条管线与persistent图配合，不是本次两条边，不能据此声称完整图流水无效。
4. 占用上限、组间重排和四wave同组都实测过。MZ是融合FFWD里的同组复用，我们保留独立F16 mix及原累加合同；在该结构下H仍慢约0.03～0.04ms。少指令、相同wave数、更多权重复用，都需要整网实测，不能当成收益。
5. 按任务单未过≥0.5%就交账停止。未更改生产hip/、分派头、src/、RE9或flags。现场双架构共60个模块与启动快照哈希全部相同，剑星保留第五刀和帧时间日志add-on；没有新增安装/备份，没有发包。

## 复现与证据

基线和原始数据在远端实验根；exe/hsaco/完整RGB/完整汇编不入仓。

- prepare.py → variants.py：复制当前生产源，生成I/P/C；stage.ps1从游戏取基线并复编30模块，build.ps1编c32候选。不要重复stage覆盖基线。
- tchain.py生成S/V/F源与host，默认保留hidden；--unsafe-no-keep仅用于重现旧生命周期缺口，不能用作候选。--sources-only只生成源。先以--unsafe-no-keep生成S/V先导的benchmark-tc/benchmark-wrap，再以--fast生成保留hidden的benchmark-fast/benchmark-fast-wrap；后者用于最终F。
- occupancy.py → group-major.py → wave-group.py：在上述实验树上依次生成O/G/H；其中H generator可单独重复。每个build-*.ps1写独立build与modules目录，宏默认0。
- suite.ps1用于I/P/O/G/C；suite-tchain.ps1用于S/V，suite-fast.ps1用于最终F，suite-wavegroup.ps1用于H。regression.ps1阻止Shipping/RE9/鬼武者游戏占用；计时外部负载出现时整批作废。
- collect.ps1、analyze-results.py核对标准RGB及AE；validate-extra.py核对压力hash、实际计数器/回绕与H替换数、现场模块未改。候选/源码/ISA身份在module-hashes、generated-source-hashes、candidate-isa；30模块初始复编及c32默认关闭双架构代码身份另存。
- 帧时间日志记录的是hook间隔。本轮只用独立NativeGameFrame ABBA量内核改动，不把整帧日志当成NR GPU计时。

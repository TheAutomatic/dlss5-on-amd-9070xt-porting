# Daniel 0.5.0 reference 逐核对照

任务 `21fc931`；基准为已安装的 `328e108` float FMA。**本轮交对应表、加权账和两个族的负结果：没有候选稳定达到0.5%，不合配方、不装机、不发包。** 内核60模块保持开工版本，无本轮新备份；17:10收到分身新宿主通知后，已只读确认 add-on `abef6155` 和 `DLSS5_DIRECT_IO=3`，后续不得覆盖它们。

## 对照范围与入口

- 168个唯一导出：70 reference、69 fast、29共享/辅助。尾部quality bool才决定reference/fast；初始化、探针、frame I/O不能按每帧一次计。`dispatch/all-kernel-map.csv` 给全量位置、metadata、host引用和默认图是否使用。
- 从PE注册表得到166个host stub、329个调用引用，再追选择分支。**默认主体154派发是host静态推导，不是新抓的GPU trace**；我方214来自已抓拓扑，其后float FMA没有改变host分派图。`layer-pairs.csv/json`按网络位置给三种几何219行多对多对应，带各入口grid/waves/VGPR/LDS/private及静态指令分类。
- 双方producer确为同一Clang21 revision `590b9320a5be90e40268759c6203c01fde121e68`，编译选项不一定相同。**数学不相同**：Daniel reference仍half FMA/half树/完整除法；我们是经批准的float FMA fast基准。本次只试保持当前基准的结构写法。
- **名字陷阱**：Daniel `reg_vit_*`是C512窗口族；`reg1d_*`才是全局ViT。
- `DLSSNR_CHAIN`未设置时持久化chain关闭，且开启要求PAD128；不能拿它解释默认reference成绩。

## 派发／融合对应

行内边界投影按消费阶段归属，融合使边界归属不完全一一对应；总数可核。

| 族／阶段 | 我们派发 | Daniel默认派发 | 关键结构差异 |
|---|---:|---:|---|
| C32（含prefix/post及我们的decoder入口） | 11 | 10 | 我们上采样独立，对方flags8边界融合 |
| C64 | 10 | 8 | 主体都整块融合；对方边界pool/up进一步融合 |
| C128 | 14 | 12 | 同上 |
| C256 | 34 | 16 | 我们每块FFN/QKV＋attention两次，对方默认每块整块一次 |
| C512 | 92 | 64 | 我们13块×7＋pool；对方16块×4，仍有多核中间buffer |
| 全局ViT | 49 | 40 | 我们每块6次并有入口gather；对方每块5次 |
| head／decoder／repack等 | 4 | 4 | 对方两次repack＋head＋decoder，归属与我方略不同 |
| 合计 | **214** | **154** | 图外codec／I/O未包含 |

我方跳42/43/46，属于**C512 decoder**，不是全局ViT；Daniel默认host遍历完整16个C512块。Swin组分别1/2/4/8 wave，不能把每kernel或每group条数直接横比。

## 指令加权结果：先排除“VALU更多”的猜测

`isa/census.json`包含全部静态分类、循环、资源；`isa/family-weighted.csv`给所有族静态×waves。`isa/family-loop-covered.csv`明确循环展开覆盖比例：C32/C64完整覆盖，C128/深层尚有未解循环及条件路径，**对应动态账保留NA**，不冒充实际执行计数。

下面是1080同处理尺寸1152下、已知循环次数加权的每帧**可达路径总和上界**（M=百万；包括部分互斥路径，不是硬件指令计数器）：

| 族／项目 | 我们 | Daniel reference |
|---|---:|---:|
| C32 issued | 982.77M | 1002.07M |
| C32普通向量槽（VOPD算两槽） | 715.29M | 830.73M |
| C32 VMEM请求指令 | **49.62M** | **21.55M** |
| C32 WMMA | 43.22M | 36.28M |
| C64 issued | 310.69M | 337.24M |
| C64普通向量槽 | 194.05M | 241.59M |
| C64 VMEM请求指令 | **16.54M** | **8.57M** |
| C64 WMMA | 16.11M | 14.84M |

普通核逐wave：C32 chain VMEM320对129，WMMA336对256；C64 bi_bo VMEM452对219，WMMA456对416。C128本方WMMA744与独立公式吻合。**不能据此说我方ALU就是瓶颈；较多读取、矩阵模拟与中间布局更值得核查。** 缓存、读取重叠和寄存器生命周期会让“少读取”不兑现速度，本轮试验正好验证了这一点。

RDNA4 +5%对应的旧→新变化确有依据：Daniel C32 `<0>` VGPR168→163、private56→0；C64 `<64,0>`168→164、private144→80，静态scratch指令分别少24/45。我们的生产C32/C64相应核已经private0、spill0，所以无法再复制一遍“去spill”收益。`isa/resource-delta.csv`与`040-to-050-delta.csv`逐核列出mov/pack/clip等变化。

## 尺寸、字节与毫秒预算

这不是同数学、同图、同尺寸的纯编译器对照：

- Daniel默认1080处理1920×1088；逐级下采样后按4补齐，所以深层仍C51260×36、ViT640，与我们的1152深层一致。少64行主要影响浅层，不能整网按像素等比例折算。
- Daniel900深层52×32、ViT448；我们50×30、ViT400。900的ViT conv还触发split4，而1080不触发（host阈值按32 MP推导）。
- Daniel post70双轴位移为0，host和ISA均证；我们为(-4,-4)，同1152分别34560／34945 waves。这个差异会改变窗口语义，不能作为逐位提速抄入。

**族排行首先按已测本方成本定位，不给静态条数强贴实测ms。** 分身的整体网络差约0.65ms也是推算值，尚没有Daniel逐族GPU计时。以下提供可复算、明确条件的毫秒预算：

| 优先核查位置 | 本方旧族账1080 ms | 可量化差异／预算 | 含义 |
|---|---:|---|---|
| C32供数 | 3.743 | 仅浅层几何等价约 **0.207ms**；QKV/proj缓存少36/12读取 | 几何项会改输出；缓存项本轮实际无达标收益 |
| C512融合／中间量 | 1.960 | mixed＋contract8逻辑读写170.39MB，640GB/s折 **0.266ms** | 若这些中间量可消除且全走显存；不是已证实际收益 |
| 全局ViT入口打包 | 1.703 | 8次pack读写26.21MB，折 **0.041ms** | 未计launch；缓存会使显存部分更小 |
| C256融合 | 1.595 | feature＋QKV逻辑读写308.81MB，折 **0.483ms**；浅层几何等价0.084ms | 原整块融合曾更慢，不能仅因对方融合就重开旧方案 |
| C64／C128 | 1.405／1.386 | 浅层几何等价 **0.077／0.075ms**；清零候选实测见下 | 普通向量槽并非更多；边界融合另需数据流验证 |

几何等价合计约0.443ms，模型为“旧本方族时间×Daniel同族waves减少比例”，并非实测。带宽等价只算逻辑字节，不是DRAM计数、更不是收益上下界；权重缓存可把实际外存成本降得很低，实际带宽未满也会增大成本。**这些项不能相加，也不能拿去扣分身的0.65ms归因。** 完整公式和900数字在 `family-budgets.json`。

Daniel内部并非没有写回：C512明确有4个中间buffer，1080每个分配1,105,920B，900每个851,968B；ViT另有临时区。`dispatch/deep-buffer-allocations.json`记录分配跨度，未冒充实际流量。

## 两族逐条对齐与试验

### P：C64/C128/C256 attention的打包清零

Daniel低半／高半先后完全覆盖同一目的寄存器，不先清零；我方builtin把old=0变成无用VGPR清零。实验默认0宏 `W2_PACK_NOZERO`，按已生产C32同款短inline ASM表达四次转换，并锁住MODE区间；非手改二进制。

8个活跃导出资源不变、零spill。C64/C128静态少72～76向量槽；每核24个空MODE段消失，96次转换回到MODE内，没有half收窄混入。C256 bo还合并了互斥分支的重复pack，不能说实际路径一定少4转换。故改动应称“去清零＋锁MODE”，不是只有一条mov。

EXACT/AE各7×12帧全部逐位对float FMA golden，84组AE所有字段也同。旧P计时因排期无法排除并发而作废；以下为新IO下两轮1000帧ABBA：

| 档位 | 新IO第1轮 Δms / % | 新IO第2轮 Δms / % |
|---|---:|---:|
|900|+0.00642 / +0.071%|-0.00958 / -0.105%|
|1080|-0.01019 / -0.083%|-0.01468 / -0.119%|

**不达0.5%，不采用。**

### Q/R/C：C32权重跨四个token tile复用

Daniel对应ISA明确重复使用权重寄存器。实验默认0宏 `CW_WEIGHT_CACHE`：Q=QKV，R=projection，C=两者。索引、MMA/K顺序与值不变，两段缓存生命周期分开，无全局restrict假设。

六个导出确实分别少36/12/48条循环加权global_load_b64；WMMA/DS/FP8转换不变，private/spill仍0。Q/C多占12～24 VGPR，R多2～8；Q/C还增加少量地址／搬运。

每种12帧1080-motion逐位，随后两档两轮200帧ABBA（弃32）：

| 候选 | 900两轮 Δms | 1080两轮 Δms |
|---|---:|---:|
|Q，仅QKV|+0.00202 / −0.00726|+0.00794 / +0.00073|
|R，仅projection|−0.00231 / +0.01022|−0.01345 / +0.01032|
|C，组合|−0.01207 / −0.01757|−0.01794 / −0.00075|

最佳约0.19%，没有合配方资格，因此在短筛止步，**未把Q/R/C冒称跑过全部EXACT/AE**，也没拿小项简单相加拼门槛。

合计228个候选逐帧hash对新基准一致（P168＋Q/R/C各12＋新IO下P两个运动用例24）。80个有效ABBA槽保留原始计时序列，独立复算均值相同；另16个旧P计时槽隔离作废。两宏默认0的C32/C64模块，对现场两架构`.text/.rodata/.note`全同；实验patch留在`HIP/experiments/daniel-kernels`，未改生产源码。


新IO下C组合又做两轮200帧短筛：900 +0.02324/+0.01834ms；1080 -0.00567/+0.01099ms；仍不达门槛，不采用。

## 复现与收尾

- 全量索引：`dispatch/all-kernel-map.csv`；按位置配对：`layer-pairs.csv/json`。
- ISA静态／loop覆盖：`isa/`；本方40活跃核：`ours/`；估算模型：`family-budgets.json`。
- 实测：`summary.json`、`timings.csv`、`timing-series.json`、`frame-hashes.csv`、`adaptive-decisions.csv`。
- 候选ISA：`candidate-isa.json`、`c32-cache-isa.json`；默认关闭身份：`default-code-identity.json`。
- 分身交付 `dafba40` 后，再通过无游戏/benchmark进程检查才开始GPU实验。只在DGX做离线审计时仅只读复制既有ISA与日志，没有抢GPU。
- `final-identity.json`是17:05分身更新前的64文件快照核对；随后分身更新了addon和flags，`current-host.json`确认内核60文件仍同、当前addon=`abef6155`、DIRECT_IO=3。本轮没有装机、没有新备份、没有发包。

## 新宿主与计时排期校正

用户17:10确认分身已安装输入直写／输出直交。只读核对addon SHA为`ABEF6155F703616070D20CE73D8357D2F19DDC76C3C03DA838D6C236CBBD5F74`，flags中`DLSS5_DIRECT_IO=3`；只允许在这套现场上做未来备份/内核替换，不能复原旧C38宿主或旧flags。

复核日志创建／修改时间，旧P两轮与分身zero-copy计时的时间区间重叠；区间不能证明连续并发，但旧guard只匹配`benchmark.exe`、不能排除`benchmark-zc.exe`，故**旧P计时全部作废隔离**（`rejected-overlap/`、`timing-intervals.json`），输出逐位结果仍有效。C32 Q/R/C短筛区间没有与分身计时重叠。

用户明确交卡后用分身新`benchmark-zc.exe`、新assets、`DIRECT_IO=3`、`BENCH_PLAIN=1`补测P两档两批及C组合短筛。离线无FSR，位2直交由游戏宿主触发，此处覆盖位1直写；网络golden仍是float FMA。全部实验guard已扩为`^benchmark`/`^rt_bench`等前缀。新宿主比较采用同一新runner与同一套IO选项，仅换候选内核。

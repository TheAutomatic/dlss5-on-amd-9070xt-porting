# 当前1080纯Network：proc1088对齐与proc1152生产首账（2026-10-06）

**对齐1920×1088 raster、双方640 ViT token后，当前FAST1仍慢1.0136ms，FAST0慢1.1428ms。** 这比900首账更清楚：差距不能由900的400/448 token口径或旧误读的500合批解释。残差仍未按族/数学/供数因果分解。

| 我方proc | FAST | 我方GPU均值ms | mochi GPU均值ms（固定1088） | 差ms | 我方CPU均值ms | mochi CPU均值ms |
|---|---:|---:|---:|---:|---:|---:|
|1088，对齐raster|1|8.8808|7.8672|+1.0136|9.0822|8.0059|
|1088，对齐raster|0|9.0258|7.8829|+1.1428|9.2206|8.0184|
|1152，生产raster|1|9.3450|7.8912|+1.4538|9.5373|8.0306|
|1152，生产raster|0|9.4913|7.9023|+1.5890|9.7008|8.0428|

1152两行明确**不同proc**；不能写成“同几何差1.45ms”。mochi基线逐组略漂移，不能单边跨组相减当严格padding成本/FAST收益；没有把三刀相加为新速度。只四组首ABBA，无刷轮。

## 权威来源与同输入

HEAD4cbf0472（核心1a22ee96），普通staged39/arch、trial三个额外模块存在但default-off不选。当前Canonical Options factory、source/core/exe、flags、modules/assets全SHA。full71/MP1/PRED0/SKIN0/AE0/historyoff/graph0/overlap0、Style1/seed0，WaveOwned/C512M32/PDL/SwinRun1/ViTStream3。FAST0/1分别。

mochi是锁d1185d2旧exe8ad3ac1c…与model2b41c888…、原48network SPV/plan（../mochi-old-lock-20261006）；每帧--chunk1 submit/fencewait，不升级HEAD。旧目录metadata前后无改，cache只复制到本lab。

共同1920×1080半精确encoded RGBAf32 gradient，非真实游戏源。HIP按2158-y镜像到1088/1152；两个processing文件的valid部分逐float-bit等于共同input，底镜像也逐位同、finite/half-exact。mochi--in-image仅upload，不做runtime_encode或sRGB转换，RGBA32F/NEAREST，shader同2158-y底mirror。两边前置控制日志Style1/128及其他四控制=1。

**640已核实际调用/计划**：我方RunGraph W1920明确vw32/vh20/n640，1088和1152都是TierGeometry、非free-grid；mochi原plan31五阶段各token640、VT effective NR_QT32/heads32。没有改对手plan凑token。更深层有效尺寸/边缘合同不因此完全相同：例如对手C512 plan36×60、token2560，而我对齐1088层logical34×60、窗口pad同样2560；同顶部raster/ViT token不是所有内部语义都一致。

## 测法与门

先1088 FAST1四槽，再1088 FAST0，再1152 FAST1/0；每组A/M/M/A、80暖160计。**首HIP raw读取移到warm之前**，80暖到160测间连续无读图/扫描，去掉900首账已知idle。GPU首尾events夹Enqueue，逐帧StreamSynchronize；CPU另记。M从GPUtotal/160平均，不拿CPU中位减GPU均值；没有逐核事件。

八HIP槽每160csv全正/finite，首/末raw0bitdiff；同FAST+proc跨A槽SHA相同。八M final RGBA全部finite/alpha1、跨所有槽SHA同，cold/steady控数据没有暗改。analysis.json保完整槽/平均/p99（只有HIP有逐帧样本，不能宣称M p99已比）。所有stdout/stderr/timing csv齐。

AMD driver32.0.31007.2048，同warm/ABBA策略；未锁频，M的@0MHz不是有效clock证据，短组热/频率漂移不作精确数微秒归因。GPU端也可含host供给间隙：Vulkan重用commandbuffer而HIP逐帧发dispatch，这层尚未拆。

## 仍待拆的成本/数值

M noise field在build阶段一次计算、逐帧读表；我prefix逐帧Box–Muller。该边界已证，但旧noise null保留，不把它自动填成1ms原因。两边math也不同：旧VT half score/64key half tree/half出口，对应实际源+SPV与小gold在../vit-math-contract-20261006；B/C数学阶梯不按名字猜累加dtype。

M按有效1080行存RGBA image、我方生成proc整幅RGB buffer，输入/输出融合和深层padding仍异；1152生产行额外工作不能全嫁接给attention。只报告受控性能与重复性，不作跨实现画质PSNR/NVIDIA一致性或FPS/HDR/FG结论。

## 结束状态

9070开前无game/rtc/benchmark/lock、D410GB；两同事明确不并行remote RTC，原子gpu.lock/15秒gamewatch/45秒单进程边界。四首ABBA结束锁释放并通知root下一家，未停止正常游戏/他人进程。仅自己的24份raw输出经SHA/finite核后从D清理，输入fixture/weights/旧模型SPV/log保留，本地/tmp保raw；final-status lock_absent=true。未安装、改玩家配置、默认或正式包。

可重放入口../../HIP/experiments/sync-network-gap1080-20261006；CPU analysis从raw/CSV重算，不再GPU。原prototype/B2后续由root排，不能把此首账直接认定某一族贡献。

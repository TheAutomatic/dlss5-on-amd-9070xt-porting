# C256 整块融合：沿 Daniel 的供数组织重开（2026-09-28）

本轮保持现行 float FMA 数学、post 位移 (-4,-4) 和 1080 档 1920×1152 工作尺寸，只试数据组织。**采用两个qt共享权重的B候选，仅1080启用：两轮整网快1.67%/1.63%，约0.20ms，超过0.5%门槛。900保持原分体，计时持平。**

## 为什么重开

历史“C256 持久化已关”其实没有实现：`transpose-persist-20260927` 只根据 PDL 的剩余收益做了成本判断，≤0.1ms 是推测。持久化调度和本轮删除 feature/QKV 全局交界不是同一件事。

真正跑过且慢的是 `c64-wave2-20260926` 整块融合：初版 spill 修到零后，C256 单独900短筛仍 +0.21068ms。换成只融合 attention 后才获得收益。旧记录没有硬件计数器，不能把剩余变慢归因为已经证实的 LDS 冲突或占用率。

## Daniel 给的结构证据

普通 C256 reference 核每8×8窗口一个组，256线程/8 waves、32KiB LDS，153 VGPR、零 private；和我们旧整块的组大小相同。flags4另有272字节 private，不能说整个家族都零spill。

他的区别主要在供数和生命周期：多个qt共享一次权重读取；lower16KiB按输入、contract、feature、AV阶段复用，upper片段区供attention消费，部分QKV保存在寄存器。upper区很可能保存Q，是数据流推断，不冒充源码确认。expanded原本就不落LDS，我们旧实现也如此。

本轮没有移植 Daniel 的 half FMA、归一化树或其它不同舍入规则，也没有采用1088行几何。

## 我们旧整块为何值得改调度

|相同64-token窗口|生产分体前段|旧整块|
|---|---|---|
|组/线程|4组×512线程|1组×256线程|
|前段wave任务|64|8|
|每wave hidden输出|64通道|128通道，四qt串行|
|feature/QKV交界|写回全局内存|留在组内|

两边expand总WMMA仍是4096次wave指令/窗口。旧整块把token的四路组并行和head半块的两路wave并行换成每wave更多工作，没有自动减少权重读取。HT2每次A只供两个expanded，生产一次A供四个；读取层级和任务粒度都变了，不能仅凭数量判定性能。

## 候选与短筛（每槽200帧，丢32帧）

|候选|组织|短筛状态|
|---|---|---|
|O|当前数学下重测旧整块|1080 motion 12帧逐位|
|L|Q片段暂存LDS，缩短寄存器生命周期|同上|
|B|两个qt成组共享FFN权重|同上|
|BL|B加Q LDS暂存|同上|
|F1 / FL|四qt成组，单hidden tile；后者加Q LDS|同上|

以上六个候选均通过同一1080-motion 12帧短筛；这不等于完整 EXACT/AE 回归。四qt、hidden_tiles=2 的构建出现spill，未跑计时。

短筛B在1080 **−0.221ms**，900 **+0.130ms**；BL为−0.223/+0.138ms，没有明确额外收益；F1/FL的1080分别−0.177/−0.182ms。因此选简单的B，900/720保留分体。O旧整块在当前1080也已−0.136ms、900+0.176ms：本轮总收益包含重新启用融合本身，不能全部归功于新权重复用。全部16组短筛/长测ABBA及逐槽数据见 `summary.json`、`timings.csv`、`timing-series.json`。

### B真实省下了什么

按ISA自然循环与源码次数加权，`c256_wave2_bi_bo` 的FFN hidden循环：

|每wave循环执行量|旧整块|B|
|---|---:|---:|
|WMMA|576|576|
|权重VMEM读请求|576|288|
|每lane逻辑权重字节|4608|2304|

权重请求减半，矩阵算术数量不变。全核循环路径加权WMMA均1320；VMEM 1316→1028，vector slots 5251→5650，说明供数减少同时引入了寄存器/搬运代价。不能拿静态WMMA条数下降冒充计算减少。

删除的feature/QKV交界按张量读写口径为900约218.10MB、1080约308.81MB（前轮 `family-budgets.json`），缓存命中和重复请求另算，不能把其640GB/s带宽等价0.34/0.48ms当本轮实省。

上述字节是逻辑请求量，不是实测DRAM流量；全核分支按可达路径累加，属于上界账。Q LDS候选多出的DS请求也不等于实际冲突或延迟。

## 派发数与接入

当前C256真实块号为encoder15～22、decoder48～55，共16块。旧部分TOPO标签滞后一个Stage，不能据此错数。

C256族34派发含16块×2，以及进入该族的pool和decoder Up各一次。单纯块内融合应为 **34→18，整网214→198**，不是34→16。仅1080路由时900保持214。

既有 `c256_wave2[_bi][_bo]` 导出仍在模块里，但生产host原先只放行C64/C128整块。候选需要小幅host档位路由；不能只换模块却声称已经启用C256融合。沿用现行权重打包、byte输入输出、post标志与PDL状态清理。

## 正式验证与结果

B候选通过EXACT/AE各7用例×12帧，共168帧对09-28 float FMA goldens逐位；所有检查帧无NaN/Inf。AE仍44复用/40刷新，84行的reuse/age/reason/relative/local/image全部相同。连同短筛六候选共240个候选帧逐位，成对基线共480行hash；`frame-hashes.csv`与`adaptive-decisions.csv`可复核。

最终路由的两档各两轮ABBA，每槽1000帧丢200，只有首尾读回；DIRECT_IO=3、BENCH_PLAIN=1、PDL=1。每次运行前检查游戏及benchmark进程前缀。离线可覆盖输入直写，游戏FSR输出直交不是本离线跑法覆盖的路径。

|档位|第一轮基线→候选 ms|第二轮基线→候选 ms|变化|
|---|---|---|---|
|900|9.051989→9.047189|9.097763→9.101487|−0.004800/+0.003724 ms，持平|
|1080|12.326469→12.120527|12.340419→12.138835|−0.205942/−0.201584 ms，−1.671%/−1.634%|

生产只保留 `W2_FFN_QT_BATCH`，源码默认0，c64-wave2配方设2；Q LDS与四qt调参未合入。C256四导出VGPR从206/190/206/190降为159/154/159/154，LDS32KiB、private0；C64/C128与C256 attention-only的ISA/资源不变。详见 `candidate-resources.csv` 与 `weighted.json`。

生产runner与实测tier runner的.text/.rdata/.data/.pdata/.xdata全同（`runner-code-identity.json`）。双架构生产与候选代码段、默认关闭对旧模块的核对见 `module-code-identity.json`。gfx1200仅编译/离线核对，真卡逐位与计时在gfx1201。

## 剑星部署

已安装，无发布包。add-on **61a81c75**基于原 **abef6155**的直通I/O源码，只改C256路由；双架构c64-wave2为gfx1200 **434cd8ef**、gfx1201 **5bcffdf6**。`DLSS5_DIRECT_IO=3`、输入shader、dxgi/OptiScaler配置全部保持原哈希，其余58个模块未变。

备份：`D:\DLSSNR-Lab\hip-backend\c256-fusion\backups\stellar-20260928-201658`。包含原add-on、两个模块和SHA256SUMS，备份及安装均做哈希读回校验；`install.ps1 -RestoreBackup <该目录>`可还原。详见 `installed.json`、`payload.json`、`current-host.json`。

实际派发已用独立trace抓到198，其中C256整块16次（bo1、bi_bo13、bi2），见 `topology.csv`。trace未用于计时。生产二进制按仓库配方重编，代码身份已与完整回归候选对齐；回归golden不换，仍用09-28 float FMA。

游戏画面及FPS由Zero本机复测；离线−0.20ms不当成游戏FPS读数。

## C512只读结论

Daniel的 `reg_vit_attn3` 合并QKV/归一化/attention，保留最后跨头projection。我们可以沿此依赖关系另写两wave/窗口/头的新核，理论上少13次交界派发；不是把C256模板通道改成512即可，本轮不强行扩写。

当前C512实际13块，Daniel16块，92对64的总派发不能直接相减作可删除量。mix/contract旧融合已有失败记录；另发现contract8路径的float contract出口可能无人消费，但删除它是独立的小优化，不是完成C512融合。本轮对此只读，不纳入C256成绩。

## 复现入口

`HIP/experiments/c256-fusion`：`prepare-hip.py`从4f0a62f7生成隔离候选源，`build.ps1`编候选；`build-runner.sh`构建分体/all-tier/tier三种runner，只有tier用于正式验收。`regression.ps1`与`validate.ps1`跑逐位和ABBA，`collect*.ps1`导出数据，`analyze-results.py`对float FMA goldens核验。`build-production.ps1`编双架构生产核；`audit.py`/`weighted.py`复核ISA资源与循环账。所有GPU运行前查游戏及benchmark进程前缀；所有生产改动仅C256。

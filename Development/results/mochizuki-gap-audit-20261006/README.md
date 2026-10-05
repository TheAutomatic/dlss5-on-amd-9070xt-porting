# mochizuki 差距审计与后续研究计划（2026-10-06）

用户优先序校准：建筑房顶闪烁仍为第一优先。本报告的mochizuki优化为第二优先；等待真实连续源期间只读CPU锁账可作备用工作，优化GPU实验按闪烁主线安排。以下“第一/第二优先”仅指优化研究内部顺序，不覆盖闪烁主线。

本轮只读研究；没有 GPU/SSH 实验、编译、安装、配置变更或发布。下列新实验均未执行。

## 结论

当前 0.41＋发布后三刀没有与锁定 mochizuki 版本重新对账。旧差距真实存在于当时口径，但不能直接代表当前差距，也不能把剩余差距全归因于数学取舍。先刷新无探针整网账，再按稳定热点拆因果。

## 已核事实与测量限制

- 当前发布 76 模块、开发载荷 78；第三刀仅真实1440/FAST1生效，900/1080不能记该收益。配置、载荷与发布包的区分见 `../../WorkingPlan.md`；安装记录见 `../../DevHistory.md:1673-1685`。
- 旧竞品对照是 mochizuki 0.0.2.5/d1185d2、我们 ec6c0199/31模块/跳42,43,46。其500帧一次提交GPU时间戳，我们逐帧HIP span含约0.04ms输出D2D；0.1～0.3ms提交影响只是估计。见 `../competitor-timing-20260930/README.md:32-49`、`../../HIP/experiments/competitor-timing/mz2.ps1:6`。
- proc相同不等于工作量相同：900旧账双方ViT为448/400token；1080还混1152与1088行。必须打印真实几何、每层token/窗口、有效块数与dispatch，不能只写HEIGHT或“同口径”。
- 事件探针把900 span约7.01变13.99ms，按每派发41.7µs均摊扣除并强制族合计对齐无探针span；PDL被串行化，还有负事件替补。该表用于诊断，不能确认精确族贡献。见 `../kernel-map-inchain-20261001/README.md:18-23`。
- DUP会改变邻接重叠：900 FFN读41.7µs，而去两段整网边际仅22.4µs；不能把DUP边际相加为整网份额。见 `../c512-qkv-pipeline-20261001/README.md:115`。
- 全空C512消融修改输出并影响下游，量到的是整网边际，不是核本体上界；8 streams无依赖实验变慢只否定该探针，不构成所有队列方案的严格上界。原负账保留，不重开。

## 对手版本锁定与现有入口

本地 `/home/lmxxf/work/aco-isa/mz` HEAD为 `4f62a8a6900a4cbf70563ea3df2c5e3348ff63a6`，不是旧测速d1185d2，本地不能读取该旧object。当前 `windows/src/core/nrvk.hpp:1035-1064` 有每帧提交及chunk批量，`nr_graph.cpp:3577`读chunk；不能据此称旧0.0.2.5已有此功能，也不能用当前源码解释旧SPV配方。

先锁旧exe/SPV/plan、源码与effective宏、模型包/权重、输入和计时边界。旧exe与Windows实验资产本轮未远程核实；缺哪项必须明确报告。旧模型包曾清理，恢复时核hash。对手当前HEAD可作线索，不能混入旧测速对照。

我们的 `../../HIP/benchmark_vit_reuse.cpp:70-78` 可复用纯Network实例与已编码输入。但它每次Enqueue后StreamSynchronize，CPU chrono打印pure_hip_median；不是GPU端时间戳。先保留同步语义，加首尾GPU事件并另列CPU wall。批量前审核pool归还/复用、PDL keep、SP计数与恢复的跨Enqueue代际安全，不能直接删sync。

## 第一优先：刷新同步纯网络账

1. 锁当前源码commit、宿主SHA、39个gfx1201模块SHA与effective flags；固定MP1/PRED0/SKIN0/AE0/full71，FAST0与当前FAST1分列；Style、seed、history/reset写明。
2. 首轮900；另外独立列生产1080/proc1152和对齐proc1088。锁valid/proc尺寸与每层token/网格；工作量不能对齐的格子显式标注。
3. 两边载入同一已编码RGBA f32输入、权重/noise；若旧mochi暂不能载入，同输入尚未闭环，不宣称数学公平对比。GPU时间从输入已驻GPU到最终RGB就绪，D2D包含与否单列；CPU wall另列。
4. 无逐核事件、无中途读回/扫图。首尾raw、finite与重复性校验；同实现换提交方式必须逐位一致，跨实现报告误差。
5. GPU单队列/原子锁/15秒游戏看门狗/磁盘门；先暖80测160的短筛，交错两轮验证稳定。平均对平均、中位对中位；坏事件或错误输出整批隔离，不刷轮。
6. 生命周期安全审核后才做1→8→旧500帧批量。分别报告GPU每帧平均与CPU吞吐；跨帧状态/资源增长或结果变化立即止。

## 第二优先：同HIP的ViT数学阶梯

保留当前16-query组织与K16顺序，FAST0/当前FAST1先立基线；锁对手配方后逐步验证：

|阶段|单次变化|进入下一阶段的条件|
|---|---|---|
|A|FAST0与当前FAST1|数值/ISA资源/时间边界已锁|
|B|仅score halfFMA与位图路线|正确性与收益证据支持继续|
|C|64-key half分母归约树|独立核实舍入顺序与资源变化|
|D|确认后再试AV截断/half末端|对手实际配方已核，B/C结果值得继续|

FAST差异记录见 `../fast-vit-c512-20261003/README.md:8`，旧M32/BIG负账见 `../vit-1080-gap-20261001/README.md:19`。当前 `../../../hip/deep_fast.hip:288-329` 是FP8 QK、f32 score位图，分母half输入/f32 WMMA累加，AV FP8输入/f32累加；不称“当前保留half累加链”。对手half树/AV截断需锁effective宏与实际产物后确认。

每步记录raw误差、有限值、与当前基线/可用NVIDIA参考的画质、VGPR/LDS/spill/状态字节及完整整网平均/p99。新增状态和资源代价属于组织变化，不能称纯数学收益。有损研究仅实验，不部署；B/C无收益不自动进入D。仅显著资源变化且新账支持时，复查旧M32交互，不重跑盲扫。

## 第三优先及封存边界

新热点账证明等待段存在后，才做局部ISA排程实验，先静态资源门再短筛；不预估收益。旧LLVM23流程及加栅栏反慢见 `../llvm23-vit-20261002/README.md:6`、`:35`；deep spill与WN4无spill仍慢见 `../gap-map-evening-20261001/README.md:38`、`:50`。旧C512 QKV估算已翻账，不能以旧+19µs为理由。

跨层窗口存在父子依赖，真实1440 CPU DAG核验度数1～4，见 `../sp1440-fast-20261005/README.md:5`；计数发布见 `../../../hip/swin_persistent.inc:93-95`。宿主逐层分配输出并绑定下一层global输入，见 `../../HIP/swin_persistent_network.h:56`、`:67`、`:104`；旧C128/C64持久化派发变化与负账见 `../swin-persistent-c128-c64-20260929/README.md:31`。不能把一个窗口寄存器直接传给下一层当通用跨层融合，暂无新候选。

ViT960大tile spill、小请求晚批复用及既往C512/持久化/编译器盲扫负账保留。没有新瓶颈证据不重开。时序真实输入缺口与Issue指纹等独立事项继续保留，不用优化实验冒充闪烁修复。

# 当前900同步纯网络首账（2026-10-06）

**首受控账显示：当前FAST1仍比锁定mochi慢约0.600ms，FAST0约0.689ms；剩余差距尚未因果拆清。** 这不是游戏FPS，也不是真实房顶画质/闪烁验收。

| 同批组 | 我们GPU均值ms | mochi GPU均值ms | 差ms | 我们CPU均值ms | mochi CPU均值ms |
|---|---:|---:|---:|---:|---:|
| FAST0 | 6.7069 | 6.0175 | +0.6894 | 6.8842 | 6.1425 |
| FAST1 | 6.6288 | 6.0285 | +0.6003 | 6.7901 | 6.1570 |

GPU均值对均值，不拿HIP CPU chrono中位数减mochi GPU均值。mochi相对我方FAST1约快9.06%。两FAST组的mochi基线略有漂移，不能把跨组相减自动写成新优化收益。

## 来源和输入合同

- 当前普通核心sourcefreeze1a22ee96及现有canonical Options factory；staged普通stock39/arch、另三个trial模块存在但**不选择/不加载**。本runner强制experimental false、historyoff/full71/MP1/PRED0/SKIN0/AE0/graph0/overlap0，WaveOwned/C512M32/PDL/SwinRun=1、ViTStream3。普通flags来自当前hip-game模板，FAST0/FAST1分列，Style1/seed0固定。实际宿主/源/factory/flags/modules/assets SHA全部归档。
- mochi严格锁d1185d2旧exe8ad3ac1c…、model2b41c888…、旧SPV和plan；源码/48SPV逐字节重建锁见../mochi-old-lock-20261006。沿旧graph组织，未改对手HEAD或旧目录。
- 共同输入为**已经编码的half-exact synthetic gradient**，1600×900 RGBA32F；我方直接读同valid数据，并按y<900?y:1798-y镜像到底部1600×960。input-contract-check.json证明valid与pad逐float-bit一致。没有真实场景来源，不称原游戏抓帧。
- 对手--in-image上传这份valid RGBA32F，source-width/height1600/900。旧CLI不执行runtime_encode，格式不是SRGB、NEAREST采样，pixel shader按同一1798-y镜像；因此不把线性HDR经过我GameCodec与对手默认gradient混比。原proprietary driver采样其已编码输入，我方直接memory读；后续模型里的half舍入差属于两实现数学，不是假装不存在。
- 对手explicit --style1 --img-seed0，日志pre conditioning=[.0078125,1,1,1,1]；我方Api style同1/128。模型都来自既有310.8恢复资产，但两个权重存储格式不相同，未用文件SHA相等冒充逐矩阵数学等价。

## 计时和结果门

顺序为F0/M/M/F0、F1/M/M/F1，每进程warm80/measure160，双方逐帧提交/同步。HIP仅输入上传一次，GPU events夹当前Enqueue，StreamSynchronize每帧；CPU另记。measured循环没有读回、扫图或逐核事件。当前final-direct路径启用，borrow调用者RGB sink，没有人为添加旧0.04ms输出D2D。mochi从TOP_OF_PIPE到BOTTOM_OF_PIPE，每passvkQueueSubmit/fencewait、mean从GPUtotal/160独立重算，--chunk1；再不称“500一次提交”。

四HIP槽160CSV全正/finite，无坏事件；每槽首尾raw0bitdiff，同FAST的两A跨进程SHA也相同。四mochi槽output RGBA全finite/alpha1、跨槽SHA全部同。没有用最终外观检查代替这些门。原始CSV/stdout/stderr、analysis.json与large-raw-hashes.json齐。

**测法精度限制**：HIP首raw读取在warm后、正式计时前，有短暂idle；四A前5帧略高，160整体均值比后155均值高约0.007～0.011ms。正式表完整保留160，不单边扣除、不重跑；M没有逐帧样本，不能对称trim。warmup-readback-sensitivity.json只给CPU复核，不把首账说成精确到数微秒的归因。未来进一步比较应把首raw放到warm之前，两边保持同一连续测量节奏。mochi日志@0MHz不可当真实clock；本轮只保存driver32.0.31007.2048与ABBA/warm策略，没有锁频实测。

## 仍不可比/未拆的项

- 我方ViT400 token、对手448；900raster同1600×960但不是完全同算量，不能把差乘层数或改plan凑token。full71已对齐，不能继续沿用旧我13个C512/他16个的跳块口径。
- 对手noise field在build预生成，计时graph读表；我方prefix逐帧生成。旧zero-noise null保留，不把这项先当0.6ms解释或已可兑现的cache优化。
- 同是逐帧提交，Vulkan重用录好的command buffer，HIP仍逐帧host发dispatch；GPU端可包含供给间隙，CPUwall不是核纯执行时间。此层未拆，不把“每帧提交已同”说成所有提交组织已相同。
- 数学（C32/归约/舍入）和fused输入/输出边界仍有差异。M按有效900行存RGBA image，我方生产RGB是processing960行buffer；padding/最终存储的工作量不同。没有拿跨实现raw误差宣称谁更近NVIDIA。
- 三刀不跨批相加为新速度；1440 SP-fast在900不生效；不能由本synthetic输入推广真实FPS/HDR/FG。

## 执行与封存

首次启动被rtc_compile并发门拦住（无GPU实验/无lock），等packager自然退出后才执行。9070无游戏，D可写/cache约411GB，单队列原子gpu.lock、15秒游戏看门狗/本进程45秒边界。没有结束正常游戏或别人的编译。两ABBA到此即止、不刷轮、不安装/改玩家配置。旧mochi目录元数据before/after无变化，复制cache只写本lab；锁释放。

自己的raw输出经完整SHA/finite/repeat检查后从9070清理；fixture输入、weights、旧模型/SPV/日志均保留，本地/tmp保留raw用于复核。final-status.json/asset-hashes.json/large-raw-hashes.json齐。可跑入口在../../HIP/experiments/sync-network-gap-20261006，先准备共同fixture和当前Options再run.ps1；分析脚本analyze.py只CPU，不再次运行GPU。

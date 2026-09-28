# 深层对齐：采用C512紧凑点运算布局（2026-09-29）

**只采用compact布局C/P。** 相对0.36，两轮长ABBA：900省0.1641/0.1756ms，1080省0.2282/0.2482ms，约两档各2%。
C是实验构建，P是整理后的生产构建，同一实现；不是两项不同优化相加。寄存器FFN R/RF及ViT float入口V都更慢，不进配方。
实验C已完成84帧EXACT＋84帧AE逐位与84组AE决策核验；生产P也完成84帧EXACT＋84帧AE，全部命中09-28 float FMA goldens，无NaN/Inf；AE44复用/40刷新、所有字段同。
已于01:02装剑星，宿主b5ab8c3a，安装读回通过。本轮不发包，DIRECT_IO=3、MAKE_RESIDENT_EVERY=60不变。

## 真正的差别是点运算工作区

Daniel C512每块FFWD→conv→QKV/attention→conv。四个buffer闭环是输入270→FFWD278→feature280→AV288→最终输出270；feature280跨attention保留作残差，QKV只留在attn3内部6KiB LDS。
1080两边有效C512都是60×36，但Daniel点运算只处理135个4×4tile，我们旧路径先shift-pack成64×40，点运算也跟着处理160个tile。
“有效尺寸相同”不能直接推出“矩阵工作量相同”。这轮把移位与补边推迟到attention读取，不改attention窗口或删padding key。

|13个活跃C512块合计|900|1080|
|---|---:|---:|
|有效尺寸/块|50×30|60×36|
|原点运算token|26,432|33,280|
|紧凑点运算token|19,552（每块1504）|28,080（每块2160）|
|FFN/projection覆盖减少|26.029%|15.625%|
|M32 mix槽容量减少|26.029%|15.000%|
|attention窗口数，前后相同|413|520|
|attention组数，前后相同|6,608|8,320|

900原6块1792token、7块2240token；紧凑布局1500有效像素只补4个尾token至1504。
1080有效2160已16对齐，不需复制补齐；M32 mix最后组仍有一个无效16token槽，故实际槽容量为2176，不能把mix工作量也说成减少15.625%。
数学沿0.36：原FMA、权重、half/FP8舍入及K顺序不变，网络1152行及原shift不变。

## 映射、buffer与派发

新attention仍遍历原shifted窗口；坐标减去sx/sy后读compact raster，越界送零A片段，保留64key、原bias坐标及softmax支持集合。
AV仅写有效raster，再由原attention projection裁切。900末4行AV未写，但没有有效像素消费者；CPU逐块双射与尾裁切26组检查全过。
每种512通道float中间buffer（mixed/contract/feature）的13块逻辑容量和：90054.13→40.04MB，108068.16→57.51MB。
每种512通道byte中间buffer（contract8/feature8/AV分配）：90013.53→10.01MB，108017.04→14.38MB。
这些是逻辑容量，不是峰值VRAM或DRAM实测字节；完整逐块账见`geometry-account.md/json`。

900仍需13次尾补齐派发，整网trace保持**198**；1080删13次shift-pack，整网**182→169**。当前两档实际trace为**198/169**。
新compact核gfx1201：64线程、VGPR141、SGPR30、LDS6144B、private0。QKV/attention工作量没删，收益来自其两侧点运算不再处理窗口padding。

## 长ABBA与生产身份

每槽1000帧弃前200帧，DIRECT_IO3、BENCH_PLAIN1，首尾RGB读回；以下为实测配对；负数表示更快。

|批次/档位|0.36基线ms|compact ms|Δms|变化|
|---|---:|---:|---:|---:|
|实验C，第1轮900|8.519428|8.355299|−0.164129|−1.927%|
|生产P，第2轮900|8.513624|8.338009|−0.175614|−2.063%|
|实验C，第1轮1080|11.572606|11.344372|−0.228234|−1.972%|
|生产P，第2轮1080|11.587956|11.339804|−0.248152|−2.141%|

C完整168帧逐位；84组AE字段差异0，覆盖reuse=0的40帧、reuse=1的44帧。P独立168帧及AE决策也全部通过；加四个短筛共384候选帧同golden。另游戏CODEC_SRGB=0现场配置12帧对拍相同，单列不混固定夹具。
生产与实测模块逐导出比较：**91个kernel函数体全部相同**；整ELF区段差异来自函数拼接顺序，不能要求物理文件hash相同来替代函数体核对。
生产host的.text/.rdata/.data/.pdata/.xdata五段与实测host相同；新宏默认关闭的两架构还原核对相同。
gfx1200只编译核对，gfx1201实际运行。生产c512-m32-mh短hash：gfx1200 **ec9e8d92**、gfx1201 **4bb9b847**；add-on **b5ab8c3a**。

## 逐位但慢的三个候选

|候选|组织|VGPR/LDS/private|900短筛Δms|1080短筛Δms|
|---|---|---|---:|---:|
|R|单wave寄存器FFN，去hidden LDS|101/0/0|+0.199551|+0.264842|
|RF|R前接mix，同wave寄存器供数|98/0/0|+0.140592|+0.298937|
|V|ViT expand直接读float、内核内打包，删独立pack|58/0/0|+0.147357|+0.337045|

三项各12帧短筛输出同，未扩为完整七组EXACT/AE。R/RF没有改K顺序，但每输出组wave从4减1、供数和存储形态变了；无LDS/低VGPR不保证更快。
V与此前producer端P/G/Q/R是不同切口，结果仍慢；最终ViT路径保持不变。完整ViT bracket实际50派发，对Daniel含两次repack的42；旧49/40账边界不同，不混比。

## Daniel FFWD确实跑起来的有限硬账

同尺寸合成非零输入/权重，HIP graph每槽捕获200次调用，3轮ABBA；比较Daniel V1/V2及我方mixM32＋FFN_t8两核。
60×36：Daniel V1相对我方两核快2.079～2.634µs；52×32快1.032～1.332µs。V2在52×32比V1慢1.307～2.530µs，60×36差异不稳定。
全部guard=0、无非法FP8/非有限float，输出确有大量非零值；不是空跑计时。
这不是实际模型延迟/画质对照：合成权重、精度/布局不同，我方还有额外派发边界。不能乘16块外推整网，也不能把Daniel900的52×32/ViT448等同我们的50×30/400。
复现与ABI见`daniel-report.md`、`micro-summary.json`、`../../HIP/experiments/deep-layers/daniel/`。

## FP8线索与停止依据

16份C512 ffwd共8,388,608权重全可精确FP8编码，half转换没有改变任何位；但这不能证明FP16/FP8 WMMA逐位。
旧block46/pattern2仅切换展开FP8就有**10个float输出元素**位模式不同，F16控制及只切contract则通过。不是“10bits”或“10ULP”。
原日志、测试/阶段隔离patch及全量census在`../../HIP/experiments/deep-layers/fp8/`；RF8本轮未构建、未运行。按已知反例关闭，不把权重格点当作算术等价证明。

## 部署与交接

基于剑星0.36宿主d2290ad7安装；保护DIRECT_IO=3、MAKE_RESIDENT_EVERY=60及其他模块，不改驻留/p99策略。
备份 `D:\DLSSNR-Lab\hip-backend\deep-layers\backups\stellar-20260929-010247`。只换add-on及两架构c512-m32-mh，其他58模块、flags、输入shader、dxgi、OptiScaler配置保持原hash；全部60模块与仓库/现场SHA256SUMS核对通过。游戏画面和2K原生AA EXACT本机读数待Zero，离线回放不覆盖FSR输出直交。

共用header的RE9 runtime也已重编并在隔离目录回放：1707×961输入、900/1080各12帧末帧hash与0.36同（b2980ada643da964 / 758674a8bbd0206d），runtime smoke通过，未装RE9。运行库完整SHA为 `0dce0f7264d614845b93757bbb4c5f9d44ecc981672c3038cf7acdafb191c8b7`。
提交见包含本报告的git记录。不发新包；全部原始回归、ABBA、trace及代码身份放本结果目录。

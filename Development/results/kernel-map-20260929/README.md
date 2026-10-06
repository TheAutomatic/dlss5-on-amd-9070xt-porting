# 全网逐核地图与前两项优化（2026-09-29，已装剑星）

**地图已覆盖全部323条有效测量；采用head分组融合H与ViT attention转置V的组合。**
组合正式168帧全部命中09-28 float FMA goldens，无NaN/Inf，AE复用决定一致。两轮长ABBA：900省0.02077～0.03643ms，1080省0.11582～0.13792ms（1.02～1.21%）。
head的同尺寸单核差距已有明显兑现，V只省一点，不能把对Daniel约50µs/块的差距说成已经抹平。
08:48已带备份装剑星；本轮不发包，不改DIRECT_IO=3、MAKE_RESIDENT_EVERY=60或其他flags。

## 计时地图怎样组成

- 我方1080现图169条派发、Daniel reference native1080图154条，共323条，每条有明确网络位置、kernel/参数/grid/threads及日志来源。
- head/pool、上下采样跨块边界按完整comparison group配对，不拆出虚构子kernel，也不重复计入融合核。
- 我方skip42/43/46按0派发单列；Daniel相应12次派发是图结构差异，不列入实现差距排名。
- ViT入口和出口Gather/repack都纳入；完整bracket边界统一后我方50对Daniel42，不能混用旧49/40。
- 浅层Daniel1088行、我方1152行，post移位也不同；原生几何和面积估计分列，同几何排名不夹带这些项。

每job各7轮TIME取中位，START核名、RESULT中位数、前后CHECK均校验；guard/invalid=0且输出nonzero>0才入图。
首次我方fixture误把增益尾区也压成±1/64，42个浅层整块输出全零，**整批169条作废**，没有挑其中127条拼回。
新fixture保结构零，矩阵与bias合成±1/64，norm/residual/skip scale设1，再走原pack；全部我方重新测量。
11条同类时延偏离超过30%的项各追加两个独立进程，原7＋7＋7共21个TIME统一取中位，不挑最快；三份日志及原始数据均保留。
最终323/323验收有效，其他312项仍各7轮。复测后仍有三条几微秒的pack项超过同类中位数30%，保留实测值及标记；不继续追逐小项，前两项选择不受其影响。复测名单、数据来源、日志SHA及映射见map-before与原始logs目录。

## 优化前同几何地图前十

单位µs；差值=我方−Daniel。每行若是核组，时间为该组各独立派发中位数之和。

|位置/比较组|Daniel µs|我方 µs|差值µs|
|---|---:|---:|---:|
|b030.head_boundary|123.721|258.881|+135.160|
|b033.attention|22.424|73.229|+50.805|
|b037.attention|22.714|72.978|+50.264|
|b031.attention|22.553|72.520|+49.967|
|b035.attention|22.933|72.450|+49.517|
|b036.attention|23.024|71.877|+48.853|
|b038.attention|22.768|71.466|+48.698|
|b034.attention|24.444|72.498|+48.054|
|b032.attention|24.277|71.435|+47.158|
|b033.qkv|31.847|49.231|+17.385|

第一项是block30及head边界的完整组，不是“纯head核耗时258.9µs”。其我方独立pool与head projection约6.3＋119µs，是本次H的实际切口。
八个ViT attention位置逐块都落在前列，决定本次第二项V；不靠挑某一异常kernel来选方向。
完整数据：[优化前逐位置CSV](map-before/position-timings.csv)、[优化后排行CSV](map-after/ranking-same-geometry.csv)、[浅层面积估计排行](map-before/ranking-area-estimate.csv)、[族汇总](map-before/family-gaps.csv)。根目录position-map.csv是结构模板，实测值在map-before/map-after。以后可逐位置更新。

## 原生总和与面积估计

|口径|我方µs|Daniel µs|我方−Daniel µs|
|---|---:|---:|---:|
|原生各独立派发中位数之和|10323.528268|10204.250706|**+119.277562**|
|逐位置按有效面积折算Daniel|10323.528268|10607.070940|**−283.542672**|

这两行都不是整帧耗时。原生总和混有几何/移位/跳块差异，不能解读成纯实现优劣；面积行只是启发式，也没有修正窗口取整、post移位和调度/cache交互。
不要用两行符号不同制造“谁更快”的结论；挑优化看同几何位置及后续真实网络ABBA。

## H：head的pool与projection合成一派发

宏`C512_HEAD_GROUP`，复用已有groupbody组织，512线程组协同完成原pool与FP16 projection；原half/FMA/量化及有效token布局不变。
旧head pool＋project两次→一次，实际trace为900档198→197、1080档169→168；没有把这一步换成Daniel不同的FP8数学。
资源：VGPR98、SGPR29、LDS16640B、private0。新入口仍须按真实组数计，不能只凭“512线程”推并行度。
独立短筛约900−0.022435ms、1080−0.118348ms；正式结论以下方组合长ABBA为准。

## V：ViT attention转置分数排布

宏`HIP_VIT_ATTN_TRANSPOSED_SCORE`，保留400/640现有导出，在既有路径内改变片段排布；WMMA数量与每输出累加顺序保持。
资源：VGPR72、SGPR16、LDS0、private0、barrier0；没有改softmax数学、half舍入或AE gate。
独立短筛约900−0.011533ms、1080−0.027545ms。微测新核多数仍在70～72µs附近，对Daniel约22～24µs的差距仍大。
本轮只收这个确定的小收益，不把静态指令减少解读成完整解决了ViT瓶颈。

没有顺手再打ViT QKV：其与Daniel的部分差别触及FP16/FP8算术边界，head剩余差距也有同类问题，照搬不能自动保证逐位。
P投影候选仅准备、未实测，不算第三刀、不进结果和配方。

## 组合整网验证与计时

组合H＋V已完成EXACT/AE各七组12帧，共168帧配对逐位；独立golden核验全部通过，AE44次复用/40次刷新、84行所有字段同；加两个短筛共192候选帧同golden，另现场CODEC_SRGB=0配置12帧相同（单列，不混固定CODEC1夹具）。
生产host与候选.text/.rdata/.data/.pdata/.xdata五段同；4份默认关闭还原与2份生产code-section核对一致，见代码身份记录。
宏默认0，生产配方只开接受项；gfx1200为编译核对，gfx1201实跑。

|正式长ABBA|基线ms|组合ms|Δms|状态|
|---|---:|---:|---:|---|
|第1轮900|8.42661750|8.39019125|−0.03642625|完成|
|第1轮1080|11.362136875|11.224219375|−0.13791750|完成|
|第2轮900|8.358016250|8.337249375|-0.020766875|完成|
|第2轮1080|11.342682500|11.226861250|-0.115821250|完成|

每槽1000帧弃前200、DIRECT_IO3/BENCH_PLAIN1、graph off/PDL1，读回首尾RGB；两轮1080均超过0.5%门槛。900改善较小，不宣称达到0.5%。以组合直接测量为准，不把短筛百分比相加。

## 地图after更新范围

已完成新head及八个attention的独立微测。after只更新这9个比较组：我方旧head两条换一条、八个attention替换；其余**159条我方派发＋154条Daniel派发**沿用同批baseline。
其中after-ours-092首轮离群，另两进程各7轮补测后合21轮取中位；其余八个新job各7轮。after表已生成，见 `map-after/`。
head为24.650469µs，原pool＋projection合125.358747µs，省100.708278µs；八个V合计省7.141097µs。更新后的独立核中位数求和：我方10215.678893、Daniel10204.250706，差+11.428187µs；面积启发式差−391.392047µs。离群项纳入21样本中位，未挑最小值。
after不叫全网重测，不当作整帧提速；真正帧时收益由组合ABBA给出。

## 载荷与部署

新add-on **ba010de7**；gfx1200 deep **8652c8c9**、mh **71fcc576**；gfx1201 deep **4f84494e**、mh **8c386562**。
基于剑星现装b5ab8c3a升级，备份 `D:\DLSSNR-Lab\hip-backend\kernel-map\backups\stellar-20260929-084855`。只换add-on及两个模块×双架构；其他56模块、flags、输入shader、dxgi和OptiScaler配置原hash，全部60模块与仓库及现场SHA256SUMS核对通过。游戏画面/2K原生AA EXACT本机FPS待Zero；不发包。
共用header的RE9 runtime也已隔离验证：1707×961输入、900/1080各12帧末帧hash与现基线相同（b2980ada643da964 / 758674a8bbd0206d），smoke通过，未装RE9。runtime SHA256：`ef6eb3747c931e7b9ac155d682b6c00b48d2fa273273fa626fd72eb45dae58b9`。离线回放不覆盖FSR输出直交，现场DIRECT_IO=3保持。提交见包含本报告的git记录。

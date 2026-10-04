# 当前工作计划（2026-10-04，朱雀）

> 只许整篇重写；历史进DevHistory，只追加。够用就交。

## 现状

- 0.40已发布，0.41未打包。fast-vit/preupscale-auto、双feed首帧修复、直接RGBA已合；全部71块/FAST1。
- 最新双游戏原生1440特化已装：剑星addonF1681283，鬼武者根/_storage_ runtimeF0A74F7D；76模块/SUMS A09EE065不变，exact模块/配置快照同步。备份native-1440-optimization-20261004/backups/20261004-113833。
- 两游戏HEIGHT auto/FREE0，配置字节保留。剑星MP3/PRED0/SKIN0（F9可变遍数），鬼武者MP3/PRED1/SKIN0（两真实遍+预测第三遍，无F9/热载）；没有替用户切真2k，现质量模式仍auto900，本刀不会使现900提速。
- 鬼武者09:50实玩900P/2k质量接近49fps、3x效果不错，未确认比此前约49提升。剑星真3旧约27fps；肤色保护观感失败已关，不将不同配置FPS混算。
- 真1440输入2560×1440，处理2560×1472，ViT40×24=960。C256既有wholeblock融合只放行此新shape，数学/模块不变。连续三轮单遍NR frame wall17.483→17.029ms、优化3x34.409→33.442，p99均改善；纯NN GPU median15.968→15.584、32.768→31.824。不是游戏总帧时，也不说明2k已稳定可玩。
- 初报20/36ms是每帧读回/CPU扫图的诊断口径，撤回作连续基线；连续1080单遍同exe参考wall10.137、GPU9.281。fixture原图来源未独立确认，运动/history是受控序列。
- 1440 FAST0/FAST1原网络逐位同、无NaN，正常19/RE9九组SAME+smoke0。旧R AE720一次异常保留未定位；同HEAD对齐baseline/AE CSV完整通过。原档control平均不慢，900p99仍略高但A/A跨批尾位置幅度覆盖，按测量分辨率内等价记录，不声称每项p99都降。
- ViT960常量化四组byte0diff，但性能有慢轮，不收生产；C512 LUT亦无稳定收益。960现有融合/stream/N64/w5 QKV已生效，没有640慢回退。
- Issue13已用5090独立原版核对并在issue回复：原post p9514.9375%与HIP14.9432%接近，RTZ后0/44值不同；这是模型当前输入响应，非所有实机闪烁根因。原post FP16不能称pre-half oracle。
- D3D↔HIP速度研究收刀：固定交接占比上升不等于绝对等待必增；CPU提交窗口已有实证。坏HIP event批弃用，不重开崩溃研究。

## 下一步

1. 继续真实2k等价优化。DUP边际C32约5.325ms最大，其次C256约2.313、ViT族约2.168、C512 FFN/投影部分约1.221；这些不能相加当整网比例。只有具体结构空间才重开旧负账，不泛扫flags。
2. SwinRun1440目前不支持，奇数/半tile行要先审producer依赖与尾部合同，不能只解除gate。ViT960常量化与LUT已止损；不做未授权有损低分辨率替代2k。
3. 真2k实玩由Zero决定：游戏NativeAA输入2560×1440并设NETWORK_FREE_RES=1，重启确保读取；不悄改现900配置，不以离线NR成本推FPS。当前优化3x仍两遍+预测。
4. 0.41前核全部ELF真实目标：旧rtc可能忽略gfx1200，预测/肤色独立核已用正确rtc；9070 gfx1201此次通过，不替其它架构验收。五LLVM23行保留，其余COMGR21。
5. 0.41打包/中英CHANGELOG/README/三包/tag发布另行任务，本轮未发布。Forza/卧龙auto实玩；剑星auto须注意native PRE1覆盖。RE9 FRAME_STATS有白名单，无热载/热键。
6. 旧R AE720异常有新证据再查；不以未定位旧runner解释新bug，不重复完整优化研究。720几何仍缺原NVIDIA参考；内存缓涨未复现不修。

## 规矩

- 具体编译/实验/安装/归档派子代理；主进程只调度审交账，保护上下文。DevHistory追加，WorkingPlan整篇重写。
- 默认正常19逐位门；新等价刀目标档三轮ABBA，无慢轮且合并p99不差。旧档identity仍需control/AA证据，不能凭小读数自行判通过；噪声判断与实际点估计均留档。
- 性能TimingOnly仅首末检查，避免每帧读回/CPU扫图改变提交节奏；区分纯NN GPU、NR frame wall、完整游戏帧时，不相加独立核时间、不拿离线ms当游戏FPS。
- 不改默认几何/求和/量化/跳块；原未量化域不做FP8，有损需用户授权并独立可选说明代价。
- 新键同步白名单/三模板中英注释≤191字节/CONFIGURATION；初始化资源与module在producer等待前准备，不在热路径Upload/moduleLoad/sync。
- GPU前game-check+原子gpu.lock，15秒看门狗；游戏开不抢GPU/换文件、不杀正常游玩。D盘≥100GB，原输出hash/统计后清理，不删权重/附件、不入库二进制。
- git只add具体相关文件，不Co-Authored-By，不自行push、不动外层仓；发版前按授权另走发布核验。

# 当前工作计划（2026-10-04，朱雀）

> 只许整篇重写；历史进DevHistory，只追加。够用就交。

## 现状

- 0.40已发布，0.41未打包。fast-vit/preupscale-auto、双feed首帧修复、直接RGBA已合；全部71块/FAST1。
- 最新双游戏ViT字节边版已装：剑星addon3A538106，鬼武者根/_storage_ runtime25A617B2（仅强度配置入口更新）；76模块/SUMS 98960584，exact模块/配置快照同步。备份vit-byteedge-formal-20261004/backups/20261004-130812。
- 两游戏HEIGHT auto/FREE0，配置字节保留。剑星MP3/PRED1/SKIN0（23:06恢复快速3x；F9只变遍数，不变预测），鬼武者MP3/PRED1/SKIN0（两真实遍+预测第三遍，无F9/热载）；没有替用户切真2k，现质量模式仍auto900，本刀不会使现900提速。
- 鬼武者09:50实玩900P/2k质量接近49fps、3x效果不错，未确认比此前约49提升。剑星23:06反馈真3约27fps，已恢复两真实遍+预测第三遍，待实玩新FPS；肤色保护观感失败已关，不将不同配置FPS混算。
- 真1440输入2560×1440，处理2560×1472，ViT40×24=960。C256既有wholeblock融合只放行此新shape，数学/模块不变。连续三轮单遍NR frame wall17.483→17.029ms、优化3x34.409→33.442，p99均改善；纯NN GPU median15.968→15.584、32.768→31.824。不是游戏总帧时，也不说明2k已稳定可玩。
- 初报20/36ms是每帧读回/CPU扫图的诊断口径，撤回作连续基线；连续1080单遍同exe参考wall10.137、GPU9.281。fixture原图来源未独立确认，运动/history是受控序列。
- 1440 FAST0/FAST1原网络逐位同、无NaN，正常19/RE9九组SAME+smoke0。旧R AE720一次异常保留未定位；同HEAD对齐baseline/AE CSV完整通过。原档control平均不慢，900p99仍略高但A/A跨批尾位置幅度覆盖，按测量分辨率内等价记录，不声称每项p99都降。
- ViT960常量化四组byte0diff，但性能有慢轮，不收生产；C512 LUT亦无稳定收益。960现有融合/stream/N64/w5 QKV已生效，没有640慢回退。
- Issue13已用5090独立原版核对并在issue回复：原post p9514.9375%与HIP14.9432%接近，RTZ后0/44值不同；这是模型当前输入响应，非所有实机闪烁根因。原post FP16不能称pre-half oracle。
- D3D↔HIP速度研究收刀：固定交接占比上升不等于绝对等待必增；CPU提交窗口已有实证。坏HIP event批弃用，不重开崩溃研究。

- **本轮现算子小步收刀**：C32固定1440原float同但有慢轮，停止不合；ViT已量化contract由half载体改byte，QKV直读、投影decode，AE缓存仍F32。构造期三配对cap齐备才选，缺一整体旧half回退，warmup预分配/预载；正常19/1440raw/三multiSkin/RE9九组与fallback皆过。
- **新同批single收益**：900/1080/1440省.053/.093/.125ms（约.7～.9%），三轮全快且合并p99不差；1440当前同批17.104→16.980ms。不和旧17.029跨批累加，不推游戏FPS。
- **Issue13现存包上传已完成**：https://gofile.io/d/FWpuapJe ，issuecomment-5976697739；API final full1152与原post有效1080明确区分，无重跑。

- **Issue13新定位已交**：原pre-down四tile独立捕获、两repeat逐byte同/无NaN，FP8存储后数据，非pre-half。小包19241B/c9dc3569已同Gofile公开，issuecomment-5977255490已回复。prefix16/16→32投影融合无独立边界，未伪造。作者test20额外偏差尚缺source/flags/模块SHA，不套最新生产，不称所有闪烁原模型；待对方可验指纹与tile再修。今晚鸣潮由用户观察，本轮不安装/部署。

- **Issue4修复已备**：PR15/新报告控制A/B/C证明选卡一直device1正确，Enqueue重绑后9次400→600+帧无错。已采纳一行hipSetDevice既有try失败封闭退出；本机单HIP设备跨线程/900/1080逐位门过，不冒充双HIP复测。候选addonA810CD51在/tmp/issue4-products，未装Magpie/两游戏，不改配置/BIOS/驱动；没有对外回复/关闭issue，线程ID实证仍缺。

- **强度文件入口已补**：RE9合法两finite数0..1盖宿主/menu，auto/空/缺省沿API/default，非法回宿主报告一次；addon/Magpie仍0..3。文件层序不改，RE9文件需重启、addon约1秒热载。默认/API/file/env900/1080 hash门及smoke过；只装鬼武者runtime25A617B2，备份strength-config-20261004/backups/20261004-200004，三配置字节不变、现强度没改。剑星native auto仍盖custom，未擅改该行。20:09鬼武者实玩无异常、与此前一样，未给新FPS/手调数值反馈。

- **C512 direct pack组合3已装**：w2f8两个byte出口去F解码/重编码，保原舍入/累加，单项慢轮拒。normal19/1440raw/multiSkin/RE9九组smoke均过；single900/1080/1440同批省.023/.042/.103ms，三轮全快+p99不差。仅双arch模块+SUMS98960584改，host/config不动，鬼武者25A仍在；备份c512-direct-whole-20261004/backups/20261004-210325，实玩待用户。不乘微核层数/跨批累计收益。

## 下一步

1. 继续真实2k等价优化。DUP边际C32约5.325ms最大，其次C256约2.313、ViT族约2.168、C512 FFN/投影部分约1.221；这些不能相加当整网比例。只有具体结构空间才重开旧负账，不泛扫flags。
2. SwinRun1440目前不支持，奇数/半tile行要先审producer依赖与尾部合同，不能只解除gate。ViT960常量化与LUT已止损；不做未授权有损低分辨率替代2k。
3. 真2k实玩由Zero决定：游戏NativeAA输入2560×1440并设NETWORK_FREE_RES=1，重启确保读取；不悄改现900配置，不以离线NR成本推FPS。当前优化3x仍两遍+预测。
4. 0.41前核全部ELF真实目标：旧rtc可能忽略gfx1200，预测/肤色独立核已用正确rtc；9070 gfx1201此次通过，不替其它架构验收。五LLVM23行保留，其余COMGR21。
5. 0.41打包/中英CHANGELOG/README/三包/tag发布另行任务，本轮未发布。Forza/卧龙auto实玩；剑星auto须注意native PRE1覆盖。RE9 FRAME_STATS有白名单，无热载/热键。
6. 旧R AE720异常有新证据再查；不以未定位旧runner解释新bug，不重复完整优化研究。720几何仍缺原NVIDIA参考；内存缓涨未复现不修。

## 默认配置

- 快速3x预测默认1，显式0保留真三遍；仅MP3启用，1/2不变。共享启动/成员和热载、三模板已同步；CPU检查通过，现装两游戏custom已1。0.41需重编宿主和采用新模板，本轮未换游戏载荷。

## 规矩

- 有人提 PR，能合入就尽量合入。

- 具体编译/实验/安装/归档派子代理；主进程只调度审交账，保护上下文。DevHistory追加，WorkingPlan整篇重写。
- 默认正常19逐位门；新等价刀目标档三轮ABBA，无慢轮且合并p99不差。旧档identity仍需control/AA证据，不能凭小读数自行判通过；噪声判断与实际点估计均留档。
- 性能TimingOnly仅首末检查，避免每帧读回/CPU扫图改变提交节奏；区分纯NN GPU、NR frame wall、完整游戏帧时，不相加独立核时间、不拿离线ms当游戏FPS。
- 不改默认几何/求和/量化/跳块；原未量化域不做FP8，有损需用户授权并独立可选说明代价。
- 新键同步白名单/三模板中英注释≤191字节/CONFIGURATION；初始化资源与module在producer等待前准备，不在热路径Upload/moduleLoad/sync。
- GPU前game-check+原子gpu.lock，15秒看门狗；游戏开不抢GPU/换文件、不杀正常游玩。D盘≥100GB，原输出hash/统计后清理，不删权重/附件、不入库二进制。
- git只add具体相关文件，不Co-Authored-By，不自行push、不动外层仓；发版前按授权另走发布核验。

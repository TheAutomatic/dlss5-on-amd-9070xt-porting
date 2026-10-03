# 当前工作计划（2026-10-04，朱雀）

> **只许整篇重写，不追加、不局部改。** 历史进DevHistory（只追加），发版改动进CHANGELOG中英。

## 现状

- 已发布0.40；0.41未打包发布。fast-vit、preupscale-auto已合并装机。
- 剑星保持预测实验：add-on **50C453C5**、74模块/SUMS **067B7DAC**。鬼武者首帧黑屏后专属回滚：runtime **2176C544**、72模块/SUMS **9D4A2024**、原MP1/无PREDICT1，Zero01:07:13确认正常。
- **MULTI_PASS_PREDICT** 默认0，仅MP3两遍+预测。剑星安装时custom PREDICT=1、MP3/native MP3、PRE1；热载开关/F9切1/2/3。鬼武者已恢复原MP1/PRE0，F9不支持。
- 默认normal19、真MP2/3兼容、预测自重复、RE9回放/smoke通过。离线约省32%，四例约49dB，history45dB且暗/色略劣，有损实验档。详情 `results/multi-pass-predict-20261004`。
- 此前Zero实玩：鬼武者GPU89～92%（旧约95%为历史读数，本条未报FPS）；剑星1x仍57～58fps。鬼武者新预测档启动失败，回滚恢复；剑星新档实玩反馈待Zero。

## 待办

1. **鬼武者集成修复**：准备预测核初始化预加载/安全热切，避免首帧热路径module load；待机器空闲受控检验未提交producer fence场景。当前只是机制假设，不覆盖正常旧版、不抢用户GPU。剑星同3x开/关预测观感/FPS待反馈。
2. **0.41前核查全部旧模块ELF目标**：旧rtc疑似忽略gfx1200参数，新预测核已用当前rtc正确重编两架构。不能只信目录/配方标签；9070 gfx1201当前体验不阻塞。
3. **0.41**：核实打包入口→三包/README与CHANGELOG中英→发布核验→tag。同步README版本头及D盘Payload的package-README-magpie.txt；预测是否发布待实玩校准。
4. Forza/卧龙auto实测（日志auto:）、F9真按键、环境变量优先级。剑星native PRE1覆盖auto，测auto须处理覆盖。
5. RE9 FRAME_STATS已进白名单，仍无热重载/热键。

## 已搁置

- 720几何无NVIDIA参考、无闪烁报告；内存缓涨复现不了不修。
- 逐位提速近渐近线，四候选复审全否，待合包队列清空；竞品剩余差距主要是数值取舍/几何。
- 低分辨率后两遍未做，本轮只做两遍预测；功耗墙上限远程不可操作。

## 规矩

- 具体编译/实验/安装/归档派子代理，主进程只调度/审交账，保护上下文；够用就交。AGENTS自动注入；results归档+DevHistory追加。
- 默认逐位19 SAME对上一版；正式新刀两档三轮ABBA无慢轮、合并p99不差。实验有损档如实记误差/失败，离线耗时不当游戏FPS。
- 有损只作可选并标代价；不做原版没量化处FP8、不做整网隔帧。
- 新键同步RE9白名单、三模板中英注释≤191字节、CONFIGURATION；默认关兼容旧模块。
- GPU前game-check/gpu.lock，15秒游戏看门狗；游戏开着不换文件不跑GPU，不终止用户游戏。D盘≥100GB，交账清帧转储，不入库二进制。
- git仅add具体文件，push前pull --rebase --autostash；代码用worktree，不加Co-Authored-By。开发闭环提交已授权，不自行push。
- 发布README中英当前版本/更新记录+CHANGELOG中英，不写内部代号/哈希；链接回来搜占位再tag。

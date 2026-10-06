# 当前FAST1连续stage稀疏计时与扰动校准

隔离当前host，只选C512 Body23–30或ViT31–38连续区间插一对start/end；每帧保标准整网pair，合计新2＋既有2 events，不逐派发插，不改数学/队列/synchronization。AE0/full71/MP1/history0、同encoded输入/proc1920×1088/640token。CPU生成及完整MinGW链接后真9070五slot按无插/C512/无插/ViT/无插交错，暖80测160。

|slot|整网GPU均ms|插入区间均ms|区间p05–p95 ms|
|---|---:|---:|---|
|无插0|8.901007|—|—|
|C5121|8.741057|0.630538|0.567284–0.700816|
|无插2|8.898152|—|—|
|ViT3|8.794038|1.279611|1.203056–1.352755|
|无插4|8.918192|—|—|

所有slot首尾raw逐位同/finite；区间内及整个host累积pdl_calls0，GPU event均正且小于整网span，当前执行是ordered。

插一pair后整网反而快约0.159ms(C512)／0.114ms(ViT)，约1.8%／1.3%，扰动不可忽略。以上stage数仅是在该插桩环境的连续范围，含提交空隙，不是无扰动核本体/精确族份额，不能均摊修正或强制和整网一致。事件可能改变驱动提交节奏/缓存与频率；这是新机制线索，不把插桩改善直接收作优化。

下一最小控制仅在C512起点：无额外pair、同位置空pair、非blockingStreamQuery、匹配CPU调用时间的delay。保持首尾raw及GPU总span/CPUframe包络双计时；API合同只保证record异步标记、query返回完成快照，不保证/证明Windows驱动flush行为。先CPU准备，再独立首ABBA，不全地图扫描。

脚本在../../HIP/experiments/sparse-stage-20261006，源码hash、CSV、summary同目录。仅隔离host、未修改生产或安装，GPU原子锁/game-check/15秒看门狗/D≥100GB，结束锁释放。

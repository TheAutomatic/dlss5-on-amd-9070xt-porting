# C512起点host提交节奏控制首ABBA

同1088/640、当前FAST1/full71/MP1/AE0/history0、共同encoded gradient与外层GPU总span/CPU Enqueue+completion包络。隔离host不改数学、资源地址、kernel或synchronization；firstraw在warm前，所有slot首尾finite/自重复floatbit0，pdl_calls0。每个控制独立none/B/B/none，80warm/160samples。

|控制|GPU平均delta ms|GPU合并p99 delta ms|CPU平均delta ms|CPU合并p99 delta ms|
|---|---:|---:|---:|---:|
|C512开始处连续记录空timed pair|−0.076064|−0.127355|−0.085244|−0.117290|
|同点单次StreamQuery|+0.168719|+0.206845|+0.079494|+0.154760|
|同点busy delay1µs（匹配pairCPUmedian）|+0.012646|+0.014779|+0.011366|−0.003760|

空pair的GPU记录间隔约69µs，CPU两调用median1µs，所以它并非零成本标记。查询全为600/NotReady，未poll、未同步。Query/delay没有复制收益，支持事件调用特有效应线索，仍不能唯一判定Windows driver flush、batch调度、缓存或频率机制，更不直接收生产刀。

[HIP StreamQuery合同](https://rocm.docs.amd.com/projects/HIP/en/latest/doxygen/html/group___stream.html)只保证完成状态快照，[Event Record合同](https://rocmdocs.amd.com/projects/HIP/en/develop/reference/hip_runtime_api/modules/event_management.html)描述异步标记；都不保证本Windows运行时内部flush行为。实验观察与API承诺分开。

下一使用完整NativeGameFrame、既有真实HDR固定输入，经原codec/bridge/NN/decode做另档与兼容门，不能只gradient作为收刀证据。脚本../../HIP/experiments/submission-pacing-20261006，源码/CSV同目录；默认、玩家配置、游戏载荷/正式包未动，GPU单队列lock/gamecheck/watchdog/盘门全执行并释放。

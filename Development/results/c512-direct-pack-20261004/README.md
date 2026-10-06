# C512 FFN direct pack：组合小筛通过，待整网（2026-10-04）

只改活跃 `split_ffn_one_w2f8`，宏`C512_DIRECT_PACK`默认0。bit1（数值1）让mix的`F(c512_hq(m))→float→pair FP8`直接用`fp8_add0(c512_hq(m))→pair FP8`；bit2（数值2）让contract最终byte出口直接`byte_F(c512_hq(r))`。二者一起为3。局部mix float仅供该pack，无残差消费者；projection残差仍来自外部原compact输入。入口ar的float pack、c512_hq复合舍入/掩码、expand Hrtz、激活FMA和全部WMMA K序均保留；普通w2/pipe/FFN_PROJ_FUSE未改。

精确性：当前F及fp8_add0函数体与`f-sweep/probe_a.hip`已有GPU全部2³²位型proof逐字符规范化一致。该proof覆盖Inf/NaN/±0/次正规，故对任意c512_hq结果可复合，不依赖“half样本推所有float”。本轮另测65536half位码scalar出口以及每码8值pair/compound：65536和524288输出byte全部0差。真实block23权重、三种动态finite FP8-grid输入、三档×三个非零变体，共27组actual FFN输出全部0差。

实际compact token是1504/2160/3680（900/1080/原生1440），不是旧shift-window1792/2240。每槽30warm+300调用，计时前两实现之外四实现各300次预热；同流event包批，end同步后读，同时保留CPU wall，无负计时。

|组合3|三轮event差 µs/FFN（candidate−baseline）|
|---|---|
|900，1504|−3.363 /−1.050 /−1.985|
|1080，2160|−0.231 /−1.223 /−0.240|
|1440，3680|−0.501 /−0.644 /−0.590|

单独1和2都有慢轮，单独拒；组合3九轮都快但绝对量小，不能乘16块声称整网收益。交主工程先whole1440短筛，仍需正式normal19/1440motion/history和三档三轮ABBA/p99才可生产。本轮未安装、未宣称全网通过。

ISA：base/macro0 964行、136FP8pack/64decode；组合3 657行、72pack/0decode。VGPR116、WMMA24、零spill不变；SGPR42→13。静态count不是动态成本保证。COMGR21 production max-ilp，双架构正确target flags0x48/0x4e；宏0 `.text/.rodata/.note` 两架构与untouched基线全部相同，完整SHA字符串/CUID差异未当执行码变化。

`experiments/c512-direct-pack`含默认0源码对应生成recipe、proof与actual FFN probe、build/run脚本；`probe.log`、`timing.csv`为原槽，`metadata.json`记录source-proof/SHA/码域/三档输入SHA/ISA。游戏检查、原子owner gpu.lock、15秒看门狗、D>100GB；锁已释放，无游戏文件/配置改动、无帧dump。基线058ec7c1，双arch模块在`D:\DLSSNR-Lab\c512-direct-pack-20261004\gfx1200|gfx1201\3.hsaco`（实验proof出口不被网络调用），主工程负责正式配方与接收。

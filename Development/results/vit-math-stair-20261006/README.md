# 当前16-query attention数学阶梯：B/C首筛负账

当前canonical FAST1为A、FAST0为已锁对账A0；本轮只在A的deep_fast-packed-fast模块隔离替换score/denominator，其他全71块、MP1/AE0/history0、Style1、seed0及输入/几何不动。不改生产/默认、安装或正式包。

- B：score先half RNE→half FMA(scale0.08953857421875/bias1.708984375)→halfclip→概率位图。其余原FP32 QK/AV、denominator、出口不变。
- C：B＋锁定mochi64-key half分母树；保16-query组织/原AV K16序，不套整套对手组织。640为十个完整chunk；400显式16key尾只作独立CPU/小核合同，不称复制448token对手。
- D未做；旧M32未重开。B/C负账只否定本实现，不证明数学无解。

实际COMGR双arch编译：A/B68VGPR、C62VGPR，LDS/private0。VGPR减少未测出实际occupancy提高；即便粗略寄存器分配粒度，两者仍可能同allocation，不能从原始VGPR反推驻留。

真9070小核：B独立精确F64公式gold161795有限输入halfcode0diff；C64queries×400/640各64输出halfcode0diff。gold来自锁定d1185d2原score和VT_chunk91–110公式，并非同GPU函数镜像。NaN/Inf语义不由有限gold推广。

同proc1920×1088/640token整网首ABBA（各slot暖80/测160、首尾raw、无逐派发events）：

|候选|平均delta ms|合并p99 delta ms|相对当前A的raw peak1 PSNR|最大绝对差|结果|
|---|---:|---:|---:|---:|---|
|B|+0.007611|−0.015198|52.20dB|0.03482|无稳定平均收益，不收|
|C|+0.036425|+0.028335|52.63dB|0.03354|两C槽均慢且尾变差，不收|

全输出finite、同slot首尾floatbit0。PSNR只是一份共同encoded synthetic gradient全71输出相对当前FAST1，非NVIDIA oracle/游戏质量保证；无性能候选，不扩完整画质门或900/1152刷轮。

实际640 kernel静态ISA位点：A/B/C WMMA5/5/4、VMEM22/22/22、VALU216/228/247、DSbpermute0/0/4、WAIT46/43/57。B scalar helper实际增加score half转换及floatclamp往返；C删den WMMA但增加half加法、shuffle和控制。这是代码组织/编译器执行代价，不能称纯数学更贵。固定请求读取未下降；静态WAIT条数不是等待周期。对手packed half线路需独立ISA支持后另立项。

结果、CSV、source/module SHA与资源元数据同目录；源在../../HIP/experiments/vit-math-stair-20261006。首个小核runner误用PowerShell自动变量$args导致无参数Usage退出，改arguments后合同门通过；不是数学失败。GPU原子lock/game-check/15秒看门狗/D约409GB，结束锁释放。gfx1200仅编译/资源门，不是真机验证。

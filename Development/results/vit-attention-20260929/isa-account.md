# ViT attention 机器码逐段账

## Daniel 0.5.0 / 0.5.1

`_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams`，reference路径。两版目标函数代码字节相同（见isa/isa.json），4396字节，110 VGPR、27 SGPR、LDS0、无spill。host dispatch为grid=(T/64,32,1)、block128；每组4 wave，每wave16 query×一个head，key循环一次64。

Q/K从blocked片段读取：每query-tile跨度16384B、head跨度512B；两条8B Q读取先驻留寄存器。其lane偏移为 `(tid&15)*16 + ((tid>>4)&1)*256`，第二片段再+8。K每轮批读四个16-key片段（相隔16384B），2×4条b64。这里给物理地址公式，不凭消费端单独猜producer逻辑通道置换。

V是channel-major：`(head*32+column)*T + key`，按8B片段读取，64-key一轮8条b64；我们V为token-major，每16-key16条u8。两者逻辑V字节量相同，发出的VMEM指令数不同。Daniel不是把完整score矩阵写LDS：score/P/AV都在寄存器，16条ds_bpermute交换半wave片段，LDS实际分配0；ds_bpermute不等于LDS矩阵存取。没有s_barrier。

reference也不是我们的0.36数值算法：QK float WMMA后有fma_mixlo_f16半精度舍入，affine用half输入的fma_mix；概率经half转换/位映射。分母用packed half加法归约并以half跨64-key累积；AV若干WMMA局部结果经mixlo/mixhi舍入累入half，结束时分母倒数再转half、packed half乘。还存在对T与valid_T差值的padding修正和分母下限。这些不能当成纯组织差异照抄。

对应0.5.0地址：循环1056b8..106264；QK WMMA105820..105874；score半精度舍入105880起；半精度分母树105fxx..10625c；局部AV WMMA1060ac起、half累积1061xx..106254；倒数1062a8..10631c；half乘及FP8输出106354起。0.5.1函数相对偏移相同，绝对地址不同。

## 我们：基线→候选（相同16-key循环）

每wave16 query×一个head，block32；T400 grid800、T640 grid1280。候选沿用grid和输入/输出字节布局，仍8次attention派发/网络；score转置是上一轮现役，已无LDS/barrier。本次进一步转置的是**分母/AV输出方向**。

| 段 | 基线多出的工作 | 分类 | 本次处理 |
|---|---|---|---|
| Q/K读取、score dot | 2个K16 FP8 WMMA | 语义必须 | 原K顺序、原读地址不变 |
| affine/clamp/位映射 | float乘后加；相对Daniel半精度/FMA多边界 | 语义必须 | 不改 |
| half→float | 每score通用from_half，展开NaN/Inf/零/denormal分支与EXEC恢复 | 源码写法；编译器没从bit-map推出范围 | clamp限定552种half位型，全部正normal（0x1c20..0x3e90）；改精确native widening |
| 概率FP8编码 | 8次单值转换、重复clamp、移位OR拼字 | 源码写法/寄存器组织 | 有界概率<2，去冗余±448 clamp；4次成对FP8转换，不变逐元素舍入 |
| 分母 | 每keytile一次half输入、float输出WMMA，跨tile按序累加 | 语义必须 | 不改key顺序，不换Daniel半精度归约 |
| AV | 每keytile两个FP8→float WMMA，float跨所有keytile累加 | 语义必须 | 交换两乘法操作数使输出转置，原K顺序保留；以逐位测试验证 |
| 倒数/写出 | 输出query在e、feature在lane，同一query重复算倒数 | 组织方式 | query改在lane，只用sum[0]做1次严格1.f/sum；写出索引相应转置，最终字节布局不变 |
| wait/delay | 大量通用转换控制流引出的依赖等待 | 上述源码展开后的编译器调度产物 | 不手删等待；由新代码重新生成 |

552种半精度位型的穷举边界证明见half-domain.py/json；所有标量half转float均精确可表示，normal范围避开flush/NaN差异。成对编码只在寄存器里改，不增加pack张量或派发。没有重跑旧P/G/Q/R、消费端float打包V、ViT入口/出口gather-pack。

## 静态循环体：同64-key口径

下面是编译后循环范围中的**静态编码指令包**；基线包含运行时不会进入的异常分支，不能当动态指令执行数，更不是周期/带宽统计。WAIT含s_delay_alu，VALU中VOPD按一个编码包算。完整按mnemonic统计和PC范围在isa/isa.json。

| 族 | 我方基线×4 | 候选×4 | Daniel一轮 |
|---|---:|---:|---:|
| VALU | 980 | 336 | 319 |
| SALU | 308 | 16 | 9 |
| branch/EXEC | 168 | 4 | 1 |
| wait/delay | 532 | 44 | 37 |
| VMEM | 72 | 72 | 16 |
| WMMA | 20 | 20 | 16 |
| ds_bpermute | 0 | 0 | 16 |

VMEM的差值主要是V：同64key，Q/K读取两边均8条b64；V我方64条u8，Daniel8条b64。逻辑上每wave均读取2048B K＋2048B V，不能把72/16倍数当DRAM字节比。WMMA差的4条是我们严格保留的分母归约。候选代码5600→2944字节，VGPR72→68，LDS均0；最终occupancy查询另见raw/occupancy.csv。

## 如何理解微秒拆账

同一批相同输入：只换native half扩大约省20µs（640）；再成对编码约省8.5µs；再AV转置约省4µs，组合约71→38µs。它们是逐步候选的实测差值，受调度相互作用影响，不应推广成通用单条指令周期。

限定V全为+1的诊断夹具中，native版本与把V读取替换成常量片段的版本先逐字节相同再计时。此反事实删除了V取数及其地址/打包相关代码，640约省6～10µs；它不是可上线内核，也不能直接当DRAM访存耗时，寄存器/调度也会改变。400首轮baseline离群保留，并加做一次重复；该项不参与生产选择。

最终与Daniel仍有差距，V的请求组织和严格float累加/分母数学均有证据不同；本轮未把剩余每一微秒唯一归到具体硬件stall。我们已用逐位候选实际消掉约三十多微秒；其余不通过改成Daniel的half数学强行追平。

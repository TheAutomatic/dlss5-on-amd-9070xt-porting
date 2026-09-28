# 深层实际组织与可执行切口

## 先修正几何前提

1080两者有效C512都是60×36，但Daniel非attention仅按4×4tile运行：P=15×9=135，FFWD/conv grid=(68,8,1)，每wave两tile，最后无效tile受mask。我们在shift-pack后的64×40=2560像素上运行相关非attention段时，工作区并不相同。有效2160相对2560少15.625%；这是点运算/矩阵工作量差，不可直接乘整网ms。

硬证据：FFWD kernarg+40=P；PC C7D50 group_x*2，C7D70检查首tile<P，C7D98第二tile=first|1，另比较P；tile数据步长8192。conv kernarg+56=P，CFF1C group_x*2，CFF40/CFF60和D0004/D003C分别检查两tile。attn3另用ceil((W-shift)/8)窗口grid且边界条件补零。于是FFWD/conv采用紧凑4×4片段，窗口shift/halo推迟到attention内部。

900 Daniel52×32=1664，P104；我方有效50×30=1500，其padding工作区1792/2240需按块shift分别核对。不可把900写成同尺寸，ViT Daniel448 vs我方400也不相同。此处应优先移植“紧凑有效区域→attention内部窗口取样”的边界，而不是扫描全零tile跳过：后者无法保留同样紧凑全局布局。

## C512四核

270/外部 → FFWD→278 → conv(残差270/外部)→280 → attn3→288 → conv(残差280)→270。四buffer每个8192P，FP8 4×4tile fragments（1080各1105920B）。不是Q/K/V三份buffer。

FFWD确实包含mix→expand→激活→contract：初段权重0，K16迭代读完整512通道；后续读取offset262144（512² FP8矩阵之后）和393216（另131072B之后），契合8组64→256→64的两组矩阵。全部中间矩阵片段留寄存器，LDS0，无barrier，不回显存。1080模板V2单wave管32token×64输出通道；900 V1单wave管16token×64输出。矩阵输入FP8直接WMMA，不能照搬到我们half扩展而不检查舍入。

|核|1080 grid|threads|VGPR/LDS/private|
|---|---|---:|---|
|reg_vit_ffwd<2,false,false>|68×8|32|157/0/0|
|reg_vit_conv<2,0,false>|68×8|32|132/0/0|
|reg_vit_attn3<false>|窗口x×窗口y×16|64|116/6144/0|
|最终conv|同68×8|32|普通同上；边界flags2/4另见JSON|

900 ffwd/conv V1分别80/72VGPR，LDS/private0。第一块外部输入变体与最后pool/up变体不能用普通核资源冒充。精确各symbol/grid/waves/metadata在abi-resources.json，原始kernarg metadata在metadata.json。

## ViT五核

expand2<1,true,false>→reg1d_conv收缩→reg1d_qkv<false,false>→reg1d_attn<1,false>→reg1d_conv投影。前后各一次repack不计进每块5次。

- expand grid T/64×32，256线程，98VGPR/LDS0/private0。输入是FP8片段：2A5E94载v78:81，2A5F80直接v78:79作为FP8 WMMA操作数，无float→FP8转换；true不是float输入标志。
- conv普通 grid T/64×8，256线程，106VGPR/LDS4096/private0。900默认设备32MP条件走split4，grid额外z4，切勿当成相同kernel。
- QKV grid T/64×12，256线程，168VGPR/LDS4096/private8。
- attention grid T/64×32，128线程，110VGPR/LDS0/private0。

与我方相比，独立输入pack是明显额外边界，但生产端顺带生成byte的P/G/Q/R已不赚；消费者直接float读取是新路线，不能称Daniel原组织。Daniel的reg1d与C512 reg_vit分清；前者为全局ViT。

## 最容易独立launch的核

优先C512普通FFWD<V2,false,false>：只有48B by-value参数、无LDS/隐式kernarg。头文件ffwd-abi.h可直接纳入runner；1080 grid68×8、block32、P135。输入/输出最小8192P=1105920B，建议分配136tile=1114112B作guard但仍传P135；output清哨兵，input尾guard清零。

参数+24必须是**真实stage0 Daniel打包权重**：至少覆盖mix262144B、expand131072B、contract131072B，总524288B；建议实际blob原长度上传。不能用全零权重的时间冒充模型时间。输入用真实C512 feature按其4×4fragment布局打包，或拷贝实际Daniel object270快照；随机/零输入只可标为launch smoke，不作为与我方模型的性能硬对照。

取得真实buffer最短办法：在已有host stage0调用点记录params中的input/weights指针，HIP DtoH拷贝object270的8192P和stage0权重原blob；本次未执行注入/采集。若主进程已有原模型字节，可依相同FP8矩阵排列重排，但尚未验证打包索引前，不把普通row-major权重直接塞进去。

API调用要一个by-value结构参数，不是把指针数组误作每字段参数。展开核expand含隐式kernarg（metadata总288B、用户32B），比FFWD更容易误填，故不优先选它。

## 结论

最有价值切口是紧凑C512点算布局，以及单wave寄存器mix+FFN；不仅少派发。数学仍对0.36，Daniel half/FMA/归约不能移植。独立launch ABI已可用，模型意义的时间对照仍要求真实packed权重与真实输入，不伪造。

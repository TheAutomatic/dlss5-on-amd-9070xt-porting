# Daniel C256 reference：离线组织分析

结论：默认普通C256核是8-wave/窗口、32KiB LDS，和我们旧 `swin_wave2_body<256>` 同一大框架；优势候选不是“更小的线程组”，而是整窗qt调度、LDS生命周期和QKV片段驻留。不能把他的half/PTX算术一并移植。

## 可直接复核的资源

来源 `d050/x/gfx1201.hsaco` metadata；主核 `_Z13k_reg_swin_mhILi256ELi0ELb0EEv9VarParams`。

|flags|VGPR|LDS bytes|private bytes|threads/waves|
|---|---:|---:|---:|---|
|0|153|32768|0|256/8|
|1|152|32768|0|256/8|
|2|151|32768|0|256/8|
|4|159|32768|272|256/8|
|8|160|32768|0|256/8|

Flags4仍有spill，不应把整个家族说成零spill。寄存器数字本身不足推算占用率，需对照实际WGP配置、分配粒度及候选编译结果。

## 窗口与LDS排布

Host已证明一个group一个8×8窗口；ISA `v70=tid>>5`，`v17=tid&31`，8个wave分摊256通道。写LDS地址可精确读出：

`v69 = (wave_id << 9) | (lane_id << 4)`

同一wave的每lane写16字节；整组一次写4096字节，四组qt分别使用offset 0、4096、8192、12288，构成下半16KiB的整个窗口。这里只声明物理地址，不能不看fragment语义就把lane直接叫像素。

这是与我们现行w2_store/Load需重点对齐的排布：Daniel在多个阶段同一时刻对四个qt执行 `ds_store_b128`/`ds_load_b128`，不是始终按qt把整个矩阵流水串行跑完。

## 阶段证据（普通flags0）

完整临时ISA在 `daniel-c256-reference.s`；原始PC保留。

|PC|可观测动作|语义解释/置信度|
|---|---|---|
|1EC908..1EC920|下半LDS四次b128 store，offset0/4096/8192/12288；随后signal/wait|输入窗口进入共享平面，确定|
|1EC97C..1ECE40|四qt LDS载入；权重global_load；两个8次K循环|FFN展开/收缩前后计算；具体小段映射须结合权重偏移，整体确定|
|1EE338..1EE674|先barrier，再覆盖同v69的四qt，最后barrier|前一共享平面读完后复用；契合FFN contracted中间特征交换|
|1EEAD4..1EEEAC|LDS四qt载入、8次K循环（每次权重地址+0x2000，界0x10000）|跨head混合，随后生成feature；推断与旧wave2相符|
|1EF594..1EF5C4|写前barrier、同v69四qt覆盖、写后barrier|mixed feature在lower16KiB，随后供QKV读取|
|1EF67C|另起 `v33=...<<6 + 0x4000`|启用upper16KiB片段区，确定|
|1EFD78|每qt `ds_store_b128 v33+qt*16`；同时多个 `v_movreld` 保存另一组片段|至少一种QKV片段进upper LDS，另一些进寄存器；不能说QKV全在寄存器|
|1F0A8C|attention四次循环中从v33载b128|前述upper片段被attention消费；很可能是Q（每qt读取）而K/V常驻寄存器。此名字是数据流推断，非源码确认|
|1F1704..1F1734|写前barrier、覆盖lower四qt、写后barrier|AV供跨head输出投影使用，确定于流水位置|
|1F1B40..1F1F1C|lower四qt读取+8次K循环|最终跨head投影；最后只写最终输出，不落全尺寸QKV|

阶段间没有独立global feature/QKV数组写回。要谨慎：global_store计数包括尾输出/边界路径，按opcode总数不能自动区分张量。

## 权重与生命周期

权重主要是global_load_b64/b128，重复同一地址base加固定offset（例如0/16/512/528/1024/1040/1536/1552），随后多个qt WMMA消费。LDS出现 `ds_load_2addr_stride64_b32` 与b128组合，是fragment方向/索引适配；不能凭此直接诊断bank conflict。

他的FFN不是把expanded巨大张量存入LDS：在第一次输入平面之后，到contracted平面覆盖之前，中间没有expanded LDS存储。我们源码也已经如此，所以这不是新收益。

Upper片段保存+`v_movreld`有意把动态索引数组限制在较短片段。普通核最终153 VGPR/0 private，说明这种组织可行，但当前float数值路线会占更多/不同寄存器，不能要求机械复刻后也153。

## 与我们旧整块写法的具体对比

`hip/wave_owned_mh.inc`：

- 164附近：head=tid/32；plane0/plane1各64*C=16KiB。线程与LDS总容量相同。
- 170以后：FFN按qt=0..3；expanded直接量化为contract输入，原本就没有expanded LDS往返。
- 223附近：contracted写plane1；barrier；跨head混合写plane0；barrier。
- 253附近：`i2 qkv[3][4][2]`（每lane48个32位字的理论数组规模），Q/K/V三类的生命周期容易横跨整个attention；实际编译是否全保留由宏决定。
- 282以后：每wave完成本head attention；AV写plane1；barrier；plane0仍持有feature供残差。
- Daniel反复用lower16KiB作阶段交换，upper用于attention每qt片段；旧版固定“feature留plane0，AV留plane1”，是生命周期组织区别，不是LDS容量区别。

## 可执行候选顺序

1. 第一候选继续复用我们的8wave和WMMA累加顺序，只消除global feature/QKV边界；不要同时复制Daniel半精度norm/FMA。编译先看VGPR/private，若零spill无法维持，先缩Q生命周期。
2. 优先测试现成 `W2_DEFER_Q` 或将Q片段写到暂时空闲的LDS后逐qt加载；K/V留寄存器。两种办法分别是重复计算/读feature与LDS暂存的取舍；不要同时做成一个无法归因的大改。
3. 若主要瓶颈是FFN权重重复读，按两个qt一组复用同一权重fragment，保持每个输出累加器K顺序；先2qt再考虑4qt。对每条输出依赖链不改乘加顺序，理论上可保持逐位，但必须实测。
4. lower平面别直接覆盖成AV直到feature残差已消费/打包保存。这里是照Daniel最容易破坏当前语义的位置；省一次barrier不值得引入跨wave读写竞态。
5. Flags4有真实scratch272，优先普通flags0/1/2/8验证组织。上下采样边界仍应共用一个候选实现，不能只报普通核收益。

这份ISA没有GPU性能计数器，无法证明旧融合慢因是bank conflict、occupancy或串行化。旧results及新ABBA应单独给证据；这里不伪造根因。

# Daniel C512 reference attn3：融合组织

确定收益方向是合并QKV与窗口attention，消除全局QKV写回/读取；不是整个C512块零中间buffer。

## Host与资源硬证据

`_Z15k_reg_vit_attn3ILb0EEv10AttnParams`：64线程、2个wave，VGPR116、SGPR29、LDS6144字节、private0/spill0。Host grid=(窗口x,窗口y,16heads)，一个group只管一个head的8×8窗口。该核属于C512窗口注意力，不是global ViT。

默认C512每块：reg_vit_ffwd → reg_vit_conv → reg_vit_attn3 → reg_vit_conv。阶段权重分别stage0/1/2/3。四个object中间buffer位于+270/+278/+280/+288，每个分配8192*P字节；900各851968B、1080各1105920B。分配跨度只证明容量，不能自动等同每次写流量。四者精确生存期/别名不在这次ISA单核中，依据dispatch/deep-buffer-allocations.json及host调用追踪继续核对；不能把四块误叫Q/K/V/output。

## LDS同步

临时完整核在 `daniel-attn3.s`，不进仓库。

QKV生成阶段出现六条ds_store_2addr_b64（PC EB908、EB910、EBBAC、EBE58、EBFA8、EC0F4），地址offset组合0/32/64/.../224；其中offset单位依ISA为8字节。全部写结束后只有一对组同步：EC114 s_barrier_signal，EC12C s_barrier_wait。

后续attention只见LDS load，未再见LDS store：EC200..EC224、ECAE0..ECCC0、ED03C/ED044。最终结果在ECF38和EDCBC两条global_store_b128路径写出。6144=3×64×32，正好容纳单head全窗口Q/K/V FP8。结合生产顺序和地址消费，这是QKV保留LDS的强证据；不需要在融合核内留下1536通道的全局QKV张量。

## 两个wave分工：已证与未证

ISA v32=tid>>5、v36=tid&31，wave_id进入矩阵/权重索引（例如EAA54为wave_id<<10加head索引）。两wave在同head内协作，随后共享完整QKV并各计算/写一部分结果。EB868比较tid<32且影响后续选择，确有wave相关处理。

尚未完整证明wave0是否固定Q、wave1固定K，或两者按token/fragment分拆后分别做QKV。不要仅凭6144字节和一条wave偏移推断精确映射。可执行候选无需复制这套未解析映射：用明确的wave=token-half设计，保持每输出K顺序，就能取得相同全局QKV消除收益。

## 与我们m32 QKV对照

`hip/c512_m32_mh.inc`：一wave计算32token×64列，64列对应同part的两个head。acc0/acc1各4个f8；每个权重fragment同时喂两个token tile。归一化通过raw[17*65]完成，j=0..31串行平方和；再经tile[16*4]打包，写全局1536列QKV。

直接融合时不能机械拼接kernel：Daniel group是64token×32通道×单head，我们现有QKV group是32token×64通道×双head，工作覆盖不同。

建议新核：group=2wave，同head，wave0/1各管32token；每wave输出该head Q/K/V到LDS，组barrier后各计算32个query。权重片段仍在32token的两tile间共享。Q/K维持原32项串行平方和、rsqrt/max/scale顺序和原q8(F())；V方向按现行attention fragment要求落LDS，避免另一次全局转置。

6144 QKV字节之外，如果沿用raw归一化临时阵列，必须按wave分区（两wave各raw/tile）或明确阶段复用，不能直接共享同raw[17*65]造成跨wave竞态。先编译看VGPR和scratch，再决定缩raw/归约优化，别同时改数学。

## 数学边界

Daniel reference含half平方/归约、完整除法修正、half舍入路径；我们当前float FMA基准的归一化/softmax并不相同。只能借调度、LDS与融合边界，不能照抄算术。工作尺寸1152、post(-4,-4)照旧。

此报告未跑GPU；没有以ISA计数伪造耗时，也没有证明全部4个全局buffer的实际每次读写量。首个候选只要求消除QKV一对派发边界，额外FFN/contract融合另外计账。

## 四个全局buffer：默认四核路径的实际角色（补核host）

已从host参数打包确认，以下+offset均指object，不是rsp上相似数值。

|object字段|默认角色|直接证据|
|---|---|---|
|+270|本块输入/前块最终输出，最后stage3写回这里；首个块可由外部输入r14替代|042f56载为FFWD输入；043a6c载为stage1残差；043d8b→args+24为stage3输出|
|+278|stage0 FFWD输出；stage1 conv主输入|042f64→FFWD输出arg；043a54→stage1 args+0|
|+280|stage1 conv输出的mixed feature；stage2 attn3输入；stage3 conv残差输入|043a83→stage1 args+24；043b19保存在rbp，043cab→attn args+0；043d69/71/76见下|
|+288|stage2 attn3输出的attention结果；stage3 conv主输入|043b20→临时slot78，043cb3/8→attn args+8；043d69/71/76见下|

Stage3的关键不是猜测：`movdqu object+280,xmm0; pshufd 0x4e; movdqa xmm0,args+0`，确切把相邻(+280,+288)交换为args(+0=288,+8=280)。stage1同一conv调用格式是args(+0=278,+8=270或0,+16=外部r14,+24=280,+40=stage1权重)；stage3为args(+0=288,+8=280,+16=0,+24=270,+40=stage3权重)。这直接证实feature残差跨attention保留。

因此默认闭环是：270/外部 → FFWD→278 → conv(残差270/外部)→280 → attn3→288 → conv(残差280)→270。QKV只在attn3核内部LDS中，不占这四个全局buffer之一。四buffer角色已经确认，单次真实读写量仍需格式/访问范围，不能拿容量乘次数直接当DRAM。

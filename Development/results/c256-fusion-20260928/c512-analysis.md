# C512少派发：本轮只读收窄

结论：有一个区别于已失败mix融合的新结构切口——**QKV/归一化与窗口attention融合，保留最后512通道projection独立**。它对应Daniel实际`reg_vit_attn3`，有明确数据依赖基础；但需要新64线程/窗口/头内核，不是把C256整块模板改成512即可。本轮应先交付C256，C512不强行写候选。另发现生产contract8路径仍写无人消费的float contract，可单独删除无效写作低成本候选，但它不减少派发，不能冒充完成C512融合。

## 当前与Daniel的差别

`Development/results/daniel-kernels-20260928/dispatch/README.md:64`起已收窄：Daniel每C512块4次：FFWD、conv、attn3、conv。其中attn3把QKV/归一化/attention合成一个64线程组，grid按窗口XY×16头。我们每块shift、mix、FFN、FFN投影、QKV+norm、attention、attention投影，共7次；活跃13块＋进入本层pool/project是92次。Daniel跑16块64次，不能直接用92−64=28推算可删除量。

我方源：`Development/HIP/hip_reference_network.h:368`，`hip/c512_m32_mh.inc`，`hip/multihead_fast_padded.hip:408`等。旧成本账`Development/results/c512-round1-20260927/README.md`：QKV M32+norm每wave32token×64输出通道/一个part，155 VGPR/5456B LDS；attention四wave/头，103VGPR/15360B LDS。900/1080 QKV边际0.4784/0.4072ms、attention0.1680/0.2167ms，都是旧基线边际测法，不能加起来当当下核实收益。

## 新切口：只合QKV→attention

- 分组：每工作组负责一个8×8窗口、一个32通道头；两wave分别负责32查询token。每wave从FFN投影输出ffn8读取全部512输入通道，按**原K片段顺序**算本头Q/K/V，保留Q/K原32项平方和顺序、rsqrt/scale/FP8出口。
- K/V必须让另一wave看到，放组内LDS；Q可留自己的寄存器或暂存LDS。完整窗口每头QKV只有`64×32×3=6144B` FP8。归一化若沿用当前raw暂存，则scratch生命周期要与QKV明确错开；6144B只是数学载荷，不是最终资源承诺。
- 两wave同步后，各自算32查询×64键：照现有attention的exp位映射、WMMA分母求和顺序、倒数修正及AV累加。直接写当前projection消费的AV格式。
- 跨头混合只在最后projection发生，故无需把16头全装一组，也无需1024线程或跨组同步。这正是区别于“C512整个块融合”的有利依赖结构。
- 每帧理论减少13次QKV→attention交界派发，删除归一化QKV的全局store与后续load，保留ffn8及AV两边全局接口。是新融合路线，不重做已关的单独QKV“一头一wave”占用率实验：成功标准是删掉跨核中间量之后的整网收益，不能仅看融合后VGPR下降。

逐位难点：当前QKV按64通道/part的M32分工，候选变32通道/全part的M32分工；单点WMMA K顺序可以保持，但Q/K串行求和、V方向、softmax归约树、窗口移位与padding必须逐项保留。不能直接采用Daniel half快速算术。2wave调度也可能把减少显存流量换成高VGPR和权重重读，因此先做单块数值＋资源账，再整网，不承诺0.5%。

## 为什么不重开mix/contract融合

`hip/deep_fast.hip:536`旧`split_ffn_fused_fp8_mix`已经做了mix→expand→contract，4wave分组，共同mixed16与hidden LDS；历史整网慢0.05ms（19.116→19.190/19.160），后来的M32 mix还进一步改善独立路径。只重新跑同融合没有新证据。

contract→projection也不是顺手一合：当前FFN按8个64通道组分别出contract；projection每个输出要全部512通道。保留原4wave/64通道组需32wave一起协作（1024线程）或重算/改变K归约，跨组原位消费又需要新同步。为了少一派发把8个producer绑成大组，本轮缺少资源与收益证据，不值得随着C256顺手扩。

## 单独可做的小件：删除dead float contract出口

当前`hip/deep_fast.hip:440`的`split_ffn_fused_fp8_t8`同写：

```
out[r*512+c] = v;           // float contract
out8[tiled(r,c)] = fp8(v);  // contract8
```

但在host的`opt.c512_proj_tiles`路径，下一步`split_projection_frag`只接`P(contract8)`，不接`P(contract)`；后者既没有Stage也没有后续消费者。可在**仅_t8入口**加默认0宏关闭float store，仍计算同一个v、仍保留原FP8字节与全部同步。先保留ABI和buffer分配最小化风险；未来再去掉无用分配。

按旧调用账，确切token合计为`6*1792+7*2240=26432`，1080为`13*2560=33280`，所以可删除float写`tokens*512*4`：900 **54,132,736B**，1080 **68,157,440B**。仅把这些字节除640GB/s是0.085/0.106ms量级的理想流量模型，不能当实测，也不计成launch收益。比混合融合更小且明确，若主任务还有余量可独立试；没有查到已测试过“_t8只删float store”的记录，但这不等于肯定没人试过。

本轮只读，不改生产，不跑GPU。

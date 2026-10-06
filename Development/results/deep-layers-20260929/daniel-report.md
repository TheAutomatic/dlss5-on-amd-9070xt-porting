# Daniel深层组织与单核实测

本轮已经将Daniel FFWD实际launch起来。以下计时是有限非零合成负载，不是模型延迟；布局与ABI来自host/HSACO，未移植其half算术。

## C512：四核与紧凑工作区

默认每块：FFWD→conv→QKV+attention→conv，16块共64派发。四个全局FP8片段buffer的闭环：270/外部→FFWD→278→conv（残差270）→280→attn3→288→conv（残差280）→270。QKV不占这四块，attn3内部6KiB LDS保存。

**有效尺寸相同不等于算力工作区相同。**1080 Daniel用P=ceil(60/4)×ceil(36/4)=135个4×4tile，每块8192P=1105920B；FFWD/conv grid=(68,8,1)，每组一wave算两tile，末尾第136tile受mask。我们相关点算段在64×40=160tile上运行，多出的padding不是attention本身必须的矩阵工作。

硬证：FFWD kernarg+40=P，PC C7D50 group_x*2、C7D70检查首tile、C7D98生成第二tile并另比较P；conv kernarg+56=P，CFF1C/CFF40/D0004同样检查。attn3另按ceil((W-shift)/8)生成窗口、边界补零。可以把shift/halo推迟到attention读取，保留点算紧凑布局；这不同于扫描零tile再跳算。

900 Daniel52×32=1664/P104；我们有效50×30=1500、padding工作区随shift为1792/2240。ViT Daniel448、我们400。900不能当作同尺寸模型对照。

FFWD合并mix→expand→激活→contract。普通V2为单wave、157VGPR/LDS0/private0；V1为80VGPR/LDS0/private0。首段完整512通道mix，权重offset0；随后expand offset262144、contract offset393216，均FP8片段。expanded不经LDS，不落全局中间张量。普通conv V2/V1分别132/72VGPR、LDS/private0。attn3每窗口/head两wave，116VGPR、6144B LDS、private0。边界flags资源另列，不能用普通核代表全部。

## ViT：五核与计数边界

每块expand2→contract conv→QKV→attention→projection conv，8块40派发；前后另有两次repack。expand输入确是已打包FP8：2A5E94加载的v78:81在2A5F80直接作为FP8 WMMA操作数，不能把模板true解释成float输入。

|核|grid|threads|VGPR/LDS/private|
|---|---|---:|---|
|expand2<1,true,false>|T/64×32|256|98/0/0|
|普通reg1d_conv（两次）|T/64×8|256|106/4096/0|
|reg1d_qkv<false,false>|T/64×12|256|168/4096/8|
|reg1d_attn<1,false>|T/64×32|128|110/0/0|

900默认32MP条件下conv可走split4（grid z=4），不是上表普通路径。我们的**整个ViT bracket计50派发**，旧族账49不含同一边界归属，不能把50/49混着比较；比较Daniel40时也须注明两次外部repack归属。额外pack确是切口，但此前producer端P/G/Q/R不赚，消费者直接float是不同方案。

## FFWD synthetic硬账

A=Daniel V1；B=Daniel V2；C=我方mixM32＋FFN_t8两kernel组合。三者在同一测试尺寸下覆盖相同token数，数学/精度和布局不同，不比较模型输出。每槽HIP graph捕获200次完整调用，事件只包一次GraphLaunch；3轮ABBA，避免CPU逐次发射空隙。

|尺寸|A/V1在A-B组，µs|B/V2，µs|A/V1在A-C组，µs|C/我方两核，µs|
|---|---|---|---|---|
|60×36|32.485 / 30.538 / 31.081|31.551 / 31.257 / 30.937|31.724 / 31.750 / 31.358|34.025 / 33.829 / 33.993|
|52×32|26.574 / 27.168 / 27.168|29.104 / 28.475 / 29.260|26.991 / 27.036 / 26.807|28.023 / 28.108 / 28.139|

60×36 V1/V2差异不稳定；52×32 V2三轮都更慢1.307～2.530µs。C比A在两尺寸分别慢2.079～2.634µs、1.032～1.332µs。不能直接乘16块或称实际模型差距，尤其A-C多一个派发边界且算术不同。

输入FP8/float±.25、权重FP8/half±1/64，确定性非零合成值。两尺寸全部guard=0、FP8 invalid=0、float非有限=0。Daniel输出非零755676/582303个字节，我方757802/584143；没有拿全零输出做假有效计时。A/B输出hash相同是本次观测，不提升为实际模型等价证明。

复现源码包 `../../HIP/experiments/deep-layers/daniel/` 含microbench.cpp、ffwd-abi.h、build-microbench.sh、README.md，无二进制。FFWD参数48B、无隐式参数；V2 grid68×8/block32。原始UTF16日志micro-60x36.log/micro-52x32.log已由主进程规范化归档，数值以results/deep-layers-20260929/micro-summary.json为准。完整mapping/ABI资源另见mapping.md、abi-resources.json；归档不需要完整ISA。

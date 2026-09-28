# Daniel 0.5.0 reference 派发对应：DGX 静态审计

## 已确定

168 个独立 kernel（原 k-gfx1201.txt 每符号出现两遍，不能当 336）。尾部 quality bool 区分 reference 70、fast 69、共享 29。全量 `all-kernel-map.json/csv` 带 metadata、host 调用点和潜在 block.x 值。**metadata max_flat_workgroup_size 是上限，不是实际 launch threads。** 自动提取 block 候选只用于检索，不可直接作动态执行次数；例如 chain 内 grid=(1,1,1) 的立即数会混入，此项必须用下面人工核定。

默认是寄存器路径：0x18003d0dc..3d12c 查询 NO_REG/SLOW_PREPOST，未设时 object+0x399=1。quality 位为 global 0x1800b6e7c，值 1 选 fast，其他选 reference。

**persistent C256 chain 默认关闭。** `DLSSNR_CHAIN` getenv 非空才令 object+0x39b=1，host 0x18003d151..163；开启还要求 mode2 PAD128（0x18003d191..1a0），否则错误。确有 `k_reg_swin_chain<256,false>`（block256，grid按驻留限额clip），但默认性能不可归给它。字符串明确此路线在 NVIDIA working extent 未验证，128基线也曾hang。

## 最关键的命名纠错

**Daniel reg_vit_* 是我们的 C512 窗口段；Daniel reg1d_* 才是我们的全局 ViT。**

证据：reg_vit_attn3<false> 在 host 0x180043b48..3c9e 使用窗口 grid=(ceil((W-shiftX)/8),ceil((H-shiftY)/8),16 heads)，block=(64,1,1)，不是对全部640 token的全局注意力。reference入口在0x180043d29；fast改用 reg_vit_attn2<true>。所以不能按字面“vit”分族，否则大头排行整族错位。

| 网络位置 | Daniel reference 寄存器族 | 我们对应 |
|---|---|---|
| prefix | reg_swin32<20,false> | c32_wave1_prefix |
| C32 | reg_swin32<flags,false> | mapped / chain / finish / finish_dcrop |
| C64/C128 | reg_swin_mh<C,flags,false> | c64/c128_wave2_{bi,bo,bi_bo} + pool_project + decoder_project |
| C256 | reg_swin_mh<256,flags,false> | FFN+QKV 核 + c256_attn_wave[_bo] + pool/decoder边界 |
| C512 | reg_vit_ffwd + reg_vit_conv + reg_vit_attn3 | shift/mix/ffn/projection/QKV/attention/project |
| ViT | expand2/reg1d_conv/reg1d_qkv/reg1d_attn | pack/expand/contract/QKV/global-attn/project |
| decoder上采样到C256/128/64/32 | reg_swin_mh / reg_swin32 的flags8 | decoder_project2x + 对应下一块 |
| head / C512 decoder | reg_head<4> / reg_decup<false> | pool/project、decoder_project2x |
| post | reg_swin32<32,false> | c32_wave1_post |

## C32～C256 可复现调用权重

`swin-schedule.csv/json` 给每块、variant、shift、grid、wave；`swin-weighted.json` 按入口合计 calls 和 waves。提供 900=1600×960、Daniel1080=1920×1088、同尺寸1080=1920×1152 三套。grid公式与shift表已从host证明；各stage W/H是网络拓扑推定，未冒充当日运行trace。

- C32 block32→1 wave/window；C64 block64→2 wave；C128 block128→4 wave；C256 block256→8 wave。所有wave32（hsaco metadata）。
- host 0x180040447..4ed 得到 gx=ceil((W-shiftX)/8), gy=ceil((H-shiftY)/8)。shift表0x18007b4c0为(0,0),(-4,-4),(-4,0),(0,-4)。
- encoder C32 blocks1..4、C64 5..8、C128 9..14、C256 15..22。flags=(first?1:0)+(last?4:0)，证据0x180038602..630。
- decoder C256 48..55、C128 56..61、C64 62..65、C32 66..69。首块flags8融合上采样（0x18003b3db）；其后普通flags0，末块flags2（0x18003b623..63c）。
- prefix flags20（0x18003782b）；post flags32（0x18003ba09）。
- 合计 C32 10 次（含prefix/post）、C64 8、C128 12、C256 16。C256 的16整块对我们32次 FFN/attn，再另看池化和上采样融合。不要把我们的单wave源码和他的8wave组在相同“条数/kernel”口径直接比。

**这些边界融合表明内部也减少部分中间写回，但尚未得到完整字节数。** 单凭 inputs/outputs zero-copy不能证明内部零写回；reg_vit/1d明显仍有多核中间buffer。准确字节账需先确定每variant输入输出格式/halo/skip-residual和实际kernel参数。未填无法证明的bytes或ms。

## 不确定范围（不要补成看似完整的动态账）

1. C512 默认全16块 vs 我们跳42/43/46后的13块，必须分别加权。现已查到C512 host主体和reference入口；未逐一还原其16块实际kernel变体与重复次数，不借用我们的13次当Daniel次数。
2. reg_vit_conv 的模板第一项1/2及flags受shape/布局选择，reg1d_conv也有1/2变体。全表列已存在的host引用；尚未确认本机1088那条分支所选具体值，不能凭“<2>新版本”宣布默认全用2。
3. 未找到逐kernel实际动态trace，14个族名不等于14次launch或14个活跃入口。程序包含大量通用fallback、探针、共享I/O和只初始化调用的w16_decode；它们均不能给每帧1次。
4. 旧我们的214派发账引用在ours-dispatch-waves.json，来源mochizuki-022静态站点×实际wave口径。该账是旧生产快照，不代表今天修改后的ISA；主代理另取当前机器码。
5. 本轮无GPU，无9070访问、无装机。所有族ms差留空；整个网11.0ms和我们12.3ms不是同尺寸、同图层工作量，不能按静态条数拆出可信ms。

复现：运行hostmap.py（原DLL+host反汇编→注册表及launch refs），再build.py（llvm-readobj metadata + 对照表和Swin权重）。configrefs.py给配置相关字符串引用。原始大ISA保留/tmp现有位置；输出没有生产修改。

## 第二轮：C512/ViT 默认路径已收窄（覆盖上面“不确定”的1/2项）

新增 `deep.py`、`deep-schedule.csv/json`、`deep-weighted.json`、`deep-geometry.json`、`deep-buffer-allocations.json`。以下是在reference、默认环境变量、9070XT历史实测32个HIP multiprocessor前提下的静态派发重建，不是实时trace。

### 首先纠正深层尺寸

默认 mode0 每次下采样 `ceil4(ceil(prev/2))`（host03d32b..03d518），只有PAD128 mode2直接/2。900由C256=100×60继续变**C512=52×32，head=28×16，T=448**；1088由C256=120×68变**C512=60×36，head=32×20，T=640**；1152同样C51260×36/head32×20/T640。token最后再按64对齐（03dbba..dbee）。

因此缩去顶层64行**并没有**同比缩小C512/ViT工作量。900下他甚至比我们50×30、25×16/400的有效深层网格更大。禁止拿1152→1088的5.56%直接乘整个网络时间。

### C512：确定每块4派发，16块合64次

- encoder host038916..038989遍历23..30；decoder03afce..03b038遍历40..47，无skip42/43/46分支，默认全16块已由host证明。现时环境若修改另议；没有访问现场日志。
- 每块：`reg_vit_ffwd → reg_vit_conv → reg_vit_attn3 → reg_vit_conv`，主体042db0..043e5e。
- 令P=ceil(Wc/4)*ceil(Hc/4)。P<128选模板第一项1；P>=128选2（042f93、0214df）。900 P104→1，1080 P135→2。
- FFWD与两次conv block32，grid=(ceil(P/V),8,1)。900=(104,8,1)，1080=(68,8,1)。二tile variant在135末尾有一个空tile，不应按136有效tile计。
- FFWD的第2bool只在block23外部输入存在时true，其余false。第1conv flags1仅block23，其他0。最后conv flags4在block30（池化输出），flags2在block47（decoder边界输出），其他0；flags由参数+0x10/+0x20/+0x40的指针存在与否决定（0214ef..510）。
- `reg_vit_attn3<false>`是QKV/归一化/attention融合，block64，grid=(ceil((Wc-shiftX)/8),ceil((Hc-shiftY)/8),16)。对应我方独立QKV及attention两核。FFWD取stage0权重，conv取stage1，attn取stage2，最终conv取stage3，追踪地址043aab、043b39、043db7可复核。
- 对我方7核/块：Daniel省去独立shift派发、把mix与FFN放在同入口、把QKV和attention放在同入口；不是依靠默认关闭的persistent chain。

### ViT：确定每块5派发，8块40次，另2次repack

host038f36以39为上界，31..38共8块；默认寄存器分支038fb7：

1. `expand2<1,true,false>`，block256，grid=(T/64,32,1)。此路径固定这个模板，末尾false不能假定调用的是同名fast变体。
2. `reg1d_conv` contract，block256。
3. `reg1d_qkv<false,false>`，block256，grid=(T/64,12,1)。QKV split阈值默认0（03a913），所以正常正T走false。
4. `reg1d_attn<1,false>`，block128，grid=(T/64,32,1)。
5. `reg1d_conv` projection，与contract同wrapper。

conv自动选择（020de0）：默认阈值-1，用设备2×MP判断：`8*(T/64)<=2*MP`且split scratch/flag buffer存在→`<1,true,false>`，grid=(T/64,8,4)；否则本例`4*(T/64)<=2*MP`→`<1,false,false>`，grid=(T/64,8,1)。临时buffer在构造03dfba/03e030确实分配。历史设备证据 `results/c128-all-phase-reuse-20260921/occupancy.txt` 为32 MP，因此900 T448用split4，1080 T640用普通。若环境变量改阈值或换卡，需重新选，不把静态预测当当日已观测。

head后/ViT结束各一次`k_repack`，block256，固定grid=(256,1,1)，其内部循环覆盖张量；host038dad..e94、03a93a..aa34。head `reg_head<4>` block32、grid=(Q,16,1)；C512 decoder `reg_decup<false>` block32、grid=(Q,8,1)，Q=ceil(headW/4)*ceil(headH/4)，900 Q28、1080 Q40。

把Swin46 + C51264 + ViT40 + repack2 + head1 + decoder1相加，**网络主体默认154次派发**（不含import/export/reproject/noise/mean/初始化）。这是静态默认图计算，不冒充现场日志；相比我们214次的差额60次，其间有16 vs13块、pool/decoder融合等口径差别。

### 中间字节：已拿到精确分配跨度，流量另列

构造03dc0b..03dd71为C512的object+270/278/280/288四个中间buffer各分配 `8192*P` 字节：900各851968B，1080各1105920B。它们是实在的全局中间张量，不是“内部全零拷贝”。这与每4×4 tile、512通道的单字节fragment容量吻合；这里只把**分配跨度**作为已证，不把它自动等同每次实际写入字节。

ViT split temporary object+2e0分配 `3*T*8192`：90011010048B、108015728640B；object+2f8 flags为`80*(T/64)`：900560B、1080800B（03df5b..03e030）。900选择split4可能读写较大临时区，不能只数少派发就宣称更少内存流量。

ISA中每个store实际字节数、边界mask和循环体仍需结合具体variant累加；本轮没有把allocated bytes写成traffic，更没有从bytes直接编毫秒差。实际动态条数的默认入口与grid现在足够主代理按族加权，运行参数改变时应保留上述条件。

## 最后定点核查：post70 的零位移是直接证据

**Daniel post70 的 shiftX=0、shiftY=0，不是暂时假设。** VarParams 起点为host栈`rbp+0xb10`，维度位于+0x18/+0x1c，位移位于+0x20/+0x24：

- `0x18003b979 xorps xmm7,xmm7`；`0x18003b9ad movups xmm7,0xb28(rbp)` 把`b28..b37`整体清零，包含两个位移`b30/b34`。
- 随后`0x18003b9fa / 03ba03`只重写`b28/b2c`为W/H；`03ba09`重写`b38`为mode32。到寄存器路径`03bc79..03bc87`仍无`b30/b34`重写。
- `03bc46..03bc67`直接将W/H除8生成grid，没有位移导致的额外边界窗口。
- HSACO `k_reg_swin32<32,false>`开头`0xb6c04 s_load_b128 s[12:15],kernarg,0x18`读W/H/shiftX/shiftY；`0xb6c14..18`将group ID乘8，`0xb6c40..44`直接加`s14/s15`（实际0）。没有在入口再硬编码-4补回位移。摘录保留`post32-reference.s`。

因此：900 Daniel post是200×120=24000个wave；1088是240×136=32640；同1152是240×144=34560。我们post_shift=3对应双轴负4的现场语义，同1152是241×145=34945，即多385wave；900201×121=24321，多321wave。**这是一项窗口划分/边界语义差异，不仅是代码效率差异。** 数字shift编号在两家表中未必相同，应比较坐标(0,0)与(-4,-4)，不要只比较“0/3”字面。既然原NVIDIA实捕采用我方post3，就不能将Daniel post0更少的wave计为逐位可移植优化。

仓库存档不含完整post32-reference.s等大ISA；原件在 `/tmp/daniel-kernels/dispatch`，本目录JSON中的host地址与源码脚本可复查。

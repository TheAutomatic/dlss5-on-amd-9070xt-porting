# C32 / ViT FFN权重复用快查：本轮不新增算子候选

结论：仍有理论上可跨token共用的权重，但没找到一处同时“小、未试过、有新的明确收益依据”的改法。ViT展开M2/M4/平衡tile/重排已有完整反例；C32跨qt复用需重构当前整块的输入→FFN→QKV流水，不是给现循环加一行宏。保留主线P/G的pack边界融合，本轮不重开以下路线。

## 当前到底复用了什么

|当前核|覆盖/共享|仍重复的地方|
|---|---|---|
|C32 `cw_body`|每wave整64-token窗口；每个qt16token；单次weight片段参与16行WMMA|qt外层4次顺序执行，FFN expand/contract权重仍跨4个qt重复读取|
|ViT expand `vit_expand_blocked_body<...,Frag>`|每wave16token×64列，输入A共用给4列片段|权重B只服务一个16-token tile，其他token tile另起wave|
|ViT contract `vit_contract_blocked_body`|每wave16token×64列，K4096分4份，A给4列片段|权重B跨token tile另读；四K分区自身权重不同，不是可共用的重复|
|ViT最终projection n64|已16token×64列，A给4列片段|扩大token方向已测过不如现n64；不是遗漏未优化|

源位置：`hip/wave_owned_c32.inc:165-269`、`hip/deep_fast.hip:307-360`、`hip/vit_stream.inc`。

## ViT：明确不重复的旧实验

- **展开M4**：`history/DevHistory-full-20260923.md:1976-1978`，四token tile共用B，最初scratch544B；解除scratch后仍整网慢约0.45ms。不是“只差把spill修掉”。
- **展开M2**：同档案`:2051`，86VGPR/零scratch，900 ABBA关19.157/19.110、开19.148/19.189，噪声级，无采用依据。tile输入同时做过，也噪声级。
- **32×32平衡tile**：`results/vit-balanced-tile-20260922/README.md`，等四累加器A2/B2比A1/B4少20%逻辑加载；原行布局更慢，换A片段布局微核可改善，但整网900+0.008794ms、1080−0.003081ms，不采用。
- **32×64八累加器**：`results/vit-eight-accumulators-20260922/README.md`，跨token共用B并配套A片段布局；微段组合快8～16%，整网两档约0～−0.1%，低于槽漂移，没兑现。不能只引用微核好看的数字重开M2。
- **K展开度4→2**：同报告明确寄存器下降/容量上升不保证提速；不是未试的“降低展开”新切口。
- **展开/收缩工作组重排**：`results/vit-group-order-20260925/README.md` GM2/4等，整网无稳定收益，不能给同一重排改名再测。
- **expand＋contract整核**：档案`:2053-2057`，保数学、LDS16.6KB、零scratch、240/400/640两输入逐位，但整网慢0.55ms；HLSL也曾慢。这里不能以省中间量为由重试。
- **ViT projection M32**：`results/m32-sweep-20260926/README.md`，32×32不如已采用16×64。现half/byte edge已经保留更好的n64方向。

上述旧实验并非证明永远不可优化；只说明本轮“同类融合收尾”没有理由再跑同一个形状。P/G不同：不改矩阵分组/累加器和已有n64，只把生产者字节输出接到消费者，删独立pack。

## C32：跨qt复用尚在，但当前不宜当小补丁

当前qt循环包含Chain/映射/Prefix/Post四类输入，FFN残差初始化，展开/收缩，half残差保存，以及完整QKV。它没有像C64/C128那样先把全窗口输入统一留LDS、再独立跑FFN，因此不能把上一轮W2的batch条件直接套上。

若做2qt共享权重，需先同时准备两份input与FFN残差，再交错ht/kt，随后分别处理QKV并保持keys/values/queries映射；Prefix还涉及噪声/历史输入，Post有两次Hrtz与skip合并。数学可做，但至少要重排一整段多模板流水，显著延长输入/FFN累加器寿命。

这恰好碰到旧C32已验证的资源问题：`results/c32-wave1-20260926/README.md`，全部窗口/隐藏展开时chain240VGPR、mapped256VGPR且spill；采用RollHidden+RollWindow后约165/174VGPR、零spill，整网才稳定改善。滚动不是失败路线，**它已经是生产中的成功路线**；重新把多个qt同时驻留会逆着这条已证实的收益方向走，需要新的ISA瓶颈证据才值得重开。

另一个看似更小的方法是把全部expand/contract权重预载到qt外寄存器。每lane单侧就约32dword，两侧64dword，还要在动态ht循环里选片段；可能增加movrel与长活跃寄存器。没有证据证明L0里这几KB权重读取是当前瓶颈，不能仅凭“少加载”推出收益。因此本轮也不做猜测性preload/restrict补丁。

本轮交付是关闭依据，没有新增kernel/host patch。未改生产、未编译、未使用GPU。

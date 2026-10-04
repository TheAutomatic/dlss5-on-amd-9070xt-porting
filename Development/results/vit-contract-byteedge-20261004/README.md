# ViT contract 已量化边改字节：小筛通过，待整网（2026-10-04）

基线 `ed5295fe`。w5f8 QKV 已用 FP8 WMMA，但 contract 仍输出 half，每次K16都再次 half→float→FP8。候选保存**原 F() 已选择的码**，QKV直接读取，projection residual精确解码回float；不改变任何矩阵K顺序、归约、half舍入或量化。跨块/AE依旧float，未改宿主。

三个新export必须整组使用：`vit_stream_contract_frag_bout`（n×1024 byte，原contract签名）、`vit_stream_qkv_frag_bin_w5f8`（同QKV权重，96×ceil(n/80)组、160线程）、`vit_stream_project_n64_bb`（byte AV+byte residual，原project签名）。宏`VIT_CONTRACT_BYTE_EDGE`默认0；启用时编译要求原native+branchless F，任一export缺失应全组回落。没有用户新开关。

**精确性依据**：原F与新helper都是 `min(max(x,-448),448)` 后同一次硬件FP8转换，输入绝对位为零时统一+0。原F再解码float→half→原QKV重编码；FP8有限值（含±0）均可half精确表示。NaN经fmax选择−448，Inf饱和至±448；所以对任意f32 x，producer不产FP8 NaN。不是用half采样推断任意f32；相同量化表达式＋有限FP8回环是证明。GPU额外检查65536half输入：保存byte、half解码float均0差、0输出NaN；256FP8码中254有限码全回环/解码0差，2 NaN码中1个重编码canonical不同，明确属producer不产生的域外码。

真实block31 contract/QKV/projection权重，合成finite hidden/skip/AV，normal0和FAST4×400/640/960，六组actual完整tuple的contract解码float、QKV byte、project float全部0差。不能代替所有块游戏输入的整网验收。

| FAST4 token | 原tuple µs（两轮） | 新tuple µs（两轮） | 差 µs |
|---|---:|---:|---:|
|400|56.050 /55.890|49.451 /49.721|−6.599 /−6.168|
|640|81.798 /83.266|70.654 /71.538|−11.143 /−11.728|
|960|130.495 /131.247|110.634 /110.947|−19.861 /−20.300|

normal0完整tuple两轮亦全部快。单独project有慢槽，**以包含producer/consumer全部成本的tuple为小筛裁判**，不把QKV局部收益冒充整网。每槽15次warm+80次，之前两实现各150次tuple预热；同流event+CPU wall，end同步后读。没有跨API时钟相减。

ISA：QKV 791→647行，VGPR146→76、零spill、WMMA18不变；64次静态half→float变0，64次FP8pack→32（余下是norm出口）。FAST4 contract1036→952行、VGPR209→208；project701→698行、VGPR120不变。双archnormal/fast所有原FUNC机器码不变，新增三export及proof核。gfx1200 flags0x48/gfx1201 0x4e；COMGR21，未换编译器。

源码及小筛在`Development/HIP/experiments/vit-contract-byteedge`；`timing.csv`为全部原槽，`proof-metadata.json`含码域/ISA/SHA，`probe-0/4.log`为原始结果。GPU锁释放；15秒game-check看门狗/原子owner锁、D>100GB，没有游戏修改和帧dump。下一步由主工程配对宿主，验normal19＋真实1440motion/history与三档三轮ABBA/p99；当前不宣称生产收益。

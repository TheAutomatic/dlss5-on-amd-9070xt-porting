# 闇、鳩的三个逐位新方向（2026-10-02 夜，光派单，子代理）

基线 = 剑星现装（add-on 7FC14ECE，HIP SUMS F6411153），宿主 benchmark-base = main cc103373。判法：19 组 SAME（-PinIdle）+ ABBA 两档三轮（每轮不慢、合并 p99 不差）。**三个方向都逐位，但没有一个过关，没有装机。** 新宏都默认 0，宏 0 时编出的 c512-m32-deep 与现装 .text 相同。lab `D:\DLSSNR-Lab\hip-backend\ideas-yi-20261002`，脚本 `Development/HIP/experiments/ideas-yi/`。

## 1. C512 跨核静态融合 → 逐位，但两档三轮都明显变慢，不收

- **先查拓扑**：块内顺序是 FFN（mix/expand/contract）→ FFN 投影 → QKV+attention → attention 投影，跨块：attention 投影 → 下一块 FFN。"FFN 投影 + QKV 投影入口"走不通：QKV 和 attention 已经合在一个核里（FUSEQKV），拆开等于退回去。gap-fusion 当时否掉 "FFN+projection" 用的是"一个 wave 做完全部 512 列、组数 752→94"的形状；本轮换一个形状：一个 WG 8 个 wave，wave 数不变。
- **做法 `C512_FFN_PROJ_FUSE 1`**（c512-m32-deep 导出 `split_ffn_proj_fused`；宿主 `HIP_C512_FFN_PROJ_FUSE 1`，按导出探测）：WG = 16 token × 8 个 wave，wave g 两段都负责通道组 g。第 1 段是 w2f8 的 FFN，逐 wave 运算不变，contract 的 E4M3 字节写进 8KB LDS（布局与 out8 tile 相同，不写 global）；WG_FENCE + 屏障；第 2 段是 split_projection_frag_body，A 从 LDS 读。每块少 1 次派发，contract8 不再落盘。
- **静态评估**：VGPR 140（两个原核分别是 116/120），LDS 8KB，没有溢出，所有 wave 一轮就能全部驻留。风险点在分布：WG 只有 94（900 档）/135（1080 档）个，每个 WG 8 个 wave 挤在同一个 CU 上，64 个 CU 摊不匀。
- **结果**：19 组 SAME。ABBA 900 +0.101/+0.086/+0.091，1080 +0.207/+0.145/+0.107ms；合并 p99 7.242→7.336、10.122→10.264。**三轮全慢**。省下的派发远比不上"工作挤在少数 CU 上"多出来的串行。跨块那一对（attention 投影 + 下一块 FFN）同样要 16 token×512 列整行，是同一个形状，还要多处理 raw 块、padding 和 crop，所以不再试。线停。

## 2. 地址间距去冲突 → 全在噪声里，不收

- 历史记录：09-22 `wmma-pitch-gap` 微测里，B tile 间距 +256B 让 span64 从 48µs 降到 22µs（DevHistory §6.4）；不过当时整个集合只改善了很少一点。
- 做法：宿主宏 `HIP_ADDR_SKEW`（默认 0，编译期整个去掉），开了以后读 `DLSS5_HIP_ADDR_SKEW_STRIDE/_MOD/_SEED/_KIND`：第 i 次普通分配平移 ((i+seed)·stride) mod mod 字节（256 对齐），kind bit0 = 权重，bit1 = 中间张量。这只改物理地址，计算不变，所以天然逐位。
- 单轮 ABBA 筛查（候选 benchmark-K + 现装模块；AA = 同一可执行文件、偏移 0）：

| 配置 | 900 | 1080 |
|---|---:|---:|
| AA（偏移 0） | +0.012 | **+0.052** |
| 256B 步长 / 4KB 内（两类） | −0.002 | +0.047 |
| 4KB / 64KB（两类） | +0.003 | −0.003 |
| 64KB / 1MB（两类） | −0.001 | +0.002 |
| 4KB / 64KB 只动权重 | +0.048 | +0.002 |
| 4KB / 64KB 只动张量 | +0.035 | −0.001 |

  每一项都没超出 AA 的噪声幅度（±0.05），也没有哪一项两档同时变快，所以按规则没进入"换分配顺序复测"那一步。频率和功耗没有单独测（脚本 `clk.ps1` 已写好，没跑）：没有任何速度信号需要它来解释，鳩"省功耗换频率"那条推论也就没有前提。结论：整网层面没有可见的缓存组/通道/MALL 冲突，微测里的地址敏感在真实核里没体现出来。

## 3. 连续舍入合成一次精确转换 → 逐位，900 档有一轮变慢，不收

- 先盘点：调用最密的几处已经被前人收割过了。`F(Hrtz)`→掩码（composite-quant，W2/C512）、`fp8(F(x))`→`+0`（f-sweep 的 byte_F），C32 的出口也都是 `fp8sat(Hrtz(x)+0)` 的形式。C32 出口想把 RTZ 往返换成掩码，`-|x|<2⁻²⁴` 这一段的符号要另外修，修正要 ≥2 条指令，比现在的成对 pkrtz（每值 1.5 条）还贵，静态评估就否了。
- 剩下的一处：C32 的 `Hrtz` 是内联汇编（`v_cvt_pkrtz_f16_f32` + `v_cvt_f32_f16`），LLVM 没法把这次加宽折进后面的乘加。新写法 `HIP_C32_RTZ_ISA 2`：同样两步，改用 builtin 写（`__builtin_amdgcn_cvt_pkrtz` + `float(half)`），LLVM 就可以把加宽并进消费者，变成 `v_fma_mix_f32`。
- 穷举（9070 真机、LLVM23，`probe_rtz.hip/.cpp`）：x 遍历全部 2³²，覆盖 Hrtz(x)、Hrtz(x)·w、Hrtz(x)+y、Hrtz(Hrtz(x)·w)、Hrtz(x)·w+y 五种形式，8 组 (w,y)（含次正规、±0、65504、−1e30），旧写法对新写法**0 处不同**。
- ISA（c32-wave1，LLVM23 配方，宏 0 编出的与现装 .text 相同）：cvt_f32_f16 从 1637 降到 944，fma_mix 从 2112 增到 2681，pkrtz 从 1366 增到 1470；但总行数 55236→56250，反而多了。
- 19 组 SAME。ABBA 900 −0.050/**+0.037**/−0.010，1080 −0.031/−0.015/−0.045；合并 p99 900 7.360→**7.433**，1080 10.106→10.062。1080 三轮都快，但 900 有一轮慢、合并 p99 变差，按规则不收。宏留在源码里，默认 1（asm），可以作合包料。

## 文件
`abba-F.txt`、`abba-R-skew.txt`；源码改动：`hip/c512_m32_deep.inc`（C512_FFN_PROJ_FUSE）、`hip/c32_fused_ffn_attention.hip`（HIP_C32_RTZ_ISA 2）、`Development/HIP/hip_reference_network.h`（HIP_C512_FFN_PROJ_FUSE、HIP_ADDR_SKEW），默认值下行为不变。

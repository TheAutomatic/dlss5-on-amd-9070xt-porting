# C512 最终投影 M32 权重共用：逐位通过，整网变慢，交负账（2026-09-29）

**结论：不收、不装剑星、不发包。** 候选宏 `C512_PROJ_M32`（`hip/multihead_fast_padded.hip`，默认0，生产配方不开）。

## 做了什么

来源：kernel-map 轮留下的未实测候选 `Development/HIP/experiments/kernel-map/projection-unmeasured/`。这次改成**不动宿主**的写法：`mh_attention_project_frag_c512` 导出名、ABI、grid（tokens/16×8 个32线程wave）都不变，开宏后第 b 个 wave 算 token tile 2·(b/8) 与 2·(b/8)+1，grid 后半直接返回。每个 K16 权重片段读一次喂两个 tile 的 WMMA；每列 scale 读一次两 tile 共用。累加器初值 Hrtz(feature*scale)、K 顺序、WMMA 操作数方向、post/crop 收尾逐字照旧。与已负账的 C512 FFN M32 不同：只动 512→512 投影，无隐层/LDS。

只影响 `multihead-fast-padded-wave-packed` 一个模块（双架构）。宏=0 编出的 .text/.rodata 与剑星现装（gfx1200 71fcc576 / gfx1201 8c386562）逐字节相同；宏=1：gfx1200 a451d293、gfx1201 af2e5946。

## 资源

| | 现役 | M32 |
|---|---:|---:|
| VGPR | 80 | 97 |
| SGPR | 28 | 38 |
| LDS / private / spill | 0 | 0 |
| 有效 wave 数 | tokens/16×8 | 减半 |

## 逐位

C256 持久化 + ViT attention 新核的现役 flat-A（=剑星现装 31 模块）对 flat-P（只换本模块），同一宿主 benchmark-base（SWIN_RUN=1、MAKE_RESIDENT_EVERY=60、DIRECT_IO=3、PDL1）：
EXACT 7用例×12帧、AE 7用例×12帧全部逐帧 SHA 相同，AE 决策 CSV 相同；900/1080 history × EXACT/AE 强制票号回绕（benchmark-roll，TICKET_START=4294967290）48帧相同。合计 216 候选帧同基线；基线本身即前轮已核 09-28 golden 的现装配方。

## 整网 ABBA（每槽1000帧弃200，A-P-P-A）

| 轮 | 档 | 基线 ms | 候选 ms | Δ |
|---|---|---:|---:|---:|
| 1 | 900 | 8.05940 | 8.21515 | **+0.156（慢1.93%）** |
| 1 | 1080 | 10.98272 | 11.04224 | **+0.060（慢0.54%）** |
| 2 | 900 | 8.09680 | 8.24621 | **+0.149（慢1.85%）** |
| 2 | 1080 | 10.97233 | 11.04433 | **+0.072（慢0.66%）** |

四槽方向一致，候选两槽都比两端基线槽慢，不是漂移。原始槽值见 full.log。

## 为什么不赚

- 这个核不是权重带宽受限：权重 512×512 FP8 只 256KB，13 个块每块一派发，全在 L2 里；省一半权重请求省的是 L2 命中，不是 DRAM。
- 代价是并行度减半：900 档 C512 token 数少（紧凑约1504），wave 数本来就只有几百个，对 64 CU 不饱和；每 wave 的串行 WMMA 链从 64 条拉长到 128 条，单 wave 时延翻倍，填不满的机器上直接变成整核时延。900 慢得多（1.9%）、1080 慢得少（0.6%）正符合"token 越少越吃亏"。
- VGPR 80→97 没有 spill，占用率不是主因。
- 与 Daniel 的 group_x*2 形状相同，但他那一路整体并行度/调度不同，形状照搬不自动赚——和 09-28"少读取不一定兑现"同一条。

**别重复**：同 grid 两 tile 共用权重的 C512 投影；若再想试，只有"不减 wave 数"的写法（例如 K 切两半、两 wave 共享 LDS 权重）才可能有意义，但这核现役单个只有约十几µs，天花板很低，不建议。

复现：`Development/HIP/experiments/c512-proj-share/`（setup.ps1 → build.ps1 → full.ps1；regression.ps1 复制自 vit-attention lab）。lab `D:\DLSSNR-Lab\hip-backend\c512-proj-share-20260929`。

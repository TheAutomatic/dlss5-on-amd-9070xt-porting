# pack8：E4M3 片段两值一条 cvt_pk 直写（W2_PACK8 推广），2026-09-27

来源：c64-block-fused（`results/c64-block-fused-20260927`）的 W2_PACK8——每个 E4M3 字节原来要 cvt（只用一半）+ and + shift + or 四五条 VALU，改成 `v_cvt_pk_fp8_f32` 一次转两个值、直接写进片段字。RDNA4 上 FP8 WMMA 与 VALU 不重叠（mochizuki 的实测结论），少一条 VALU 就是少一条的时间。

## 各模块

| 宏（默认 0） | 位置 | 改到的生产模块 | ISA（gfx1201，整模块） | 逐位 | 900 / 1080 ms（ABBA，槽 0/3 基线、1/2 候选） |
|---|---|---|---|---|---|
| `CW_PACK8` | `hip/wave_owned_c32.inc`（10 处 `put_bits(a,e,fp8(x))` 的 8 字节片段） | c32-wave1 | 指令 43056→40813（−5.2%），VALU 27483→25451（−7.4%），VGPR 合计 2627→2541 | 7 用例 ×12 帧全同 | 10.68→10.18（−4.7%）/ 14.98→14.24（−4.9%） |
| `W2_PACK8` | `hip/wave_owned_mh.inc`（上一实验） | c64-wave2（C64/C128/C256 与 C256 注意力） | 指令 213627→193785（−9.3%），VALU 125561→110345（−12%） | 同 | 上一实验 −4% |
| `DF_PACK8` | `hip/deep_fast.hip`、`vit_wide_deep.inc`（8 处 `pack()` 循环） | deep_fast、deep_fast-packed、c512-m32-deep、vit-wide-deep | 指令 −0.5%～−1.7% | 7 用例全同 | 10.74→10.80 / 15.00→15.08（不赚，噪声内偏慢）——**不采用** |
| MF（multihead_fast_padded 的 `pack()` 循环） | — | 无（两处都在生产关闭的分支里） | — | — | 已撤回 |

C32 的 `fp8()` 没有 ±0 选择（与 MH 的 `q8_fused_round` 不同），所以 `CW_PACK8` 只是"同一个 clamp + 成对转换"，逐元素语义不变；clamp 跟随现行 `HIP_C32_BRANCHLESS_F`（fminf/fmaxf）或 `HIP_FP8_SAT_MODE 3`（med3）。

## 全开候选 ALL = CW_PACK8 + W2_PACK8

只换 c32-wave1、c64-wave2 两个模块；其余 27 个与 0.32 装机代码段相同（`hip/compare-modules.py`；已知的 3 个旧后备除外）。

- 逐位：900/1080 静态、运动，720 运动，900/1080 历史帧，7 用例 × 12 帧全同。
- 计时两批（1000 帧去前 200）：
  - 900：10.696/10.778 → 9.786/9.818；第二批 10.822/10.817 → 9.888/9.886 ms（约 −0.94ms，**−8.7%**）
  - 1080：14.998/15.025 → 13.627/13.649；第二批 15.026/15.050 → 13.669/13.680 ms（约 −1.37ms，**−9.1%**）
- 9070 上 Magpie 进程开着但未在缩放，两批一致。

候选 hash 见 `candidate-sha256.txt`；构建 `Development/HIP/experiments/pack8/build.ps1`（生产配方 `hip/build-modules.ps1` 新增 `-ExtraDefines`），回归 `regression.ps1 -Set ALL`。生产配方未改（仍复现 0.32），下次发包在 c32-wave1、c64-wave2 两行加宏。

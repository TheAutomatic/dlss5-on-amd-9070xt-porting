# 复合量化推广到 C512 `F(Hrtz(acc))`（2026-09-30）：证明成立，逐位，按新规收下并装机

**结论**：C512 两处 f32 出口 `F(Hrtz(acc))` 换成 `F(bits(acc)&0xffffe000)`（宏 `C512_F_MASK`，`hip/deep_fast.hip`，源码默认 0，c512-m32-deep 与 deep_fast-packed 配方写 1）：`split_mix_blocked_h16w_m32`（mix）与 `split_ffn_fused_fp8_t8`（contract）。half 那次 RTZ 保留，只省 f32→f16→f32 往返。CPU＋GPU 2³² 穷举＋输入域证明；逐位 19 组 SAME；三轮 ABBA 两档 6 个 avg 全为正。只换两个模块，宿主/RE9 runtime 不变。已装，没发包。

## 1. F 对 −0 的处理与穷举

- 生产 F（deep_fast，NATIVE_FP8_F＋BRANCHLESS_F）：`|x|==0 ? +0 : cvt_f32_fp8(cvt_pk_fp8_f32(fminf(fmaxf(x,-448),448)))`。输出是 float，所以 +0/−0 算不同结果。
- 不同只可能在：负的 0<|x|<2⁻²⁴——原式 Hrtz 得 −0，F 走 `a==0` 给 **+0**；掩码后仍是负微小数，F 经 FP8 得 **−0**。
- **CPU**（`cpu_proof_f.c`，全部 2³²）：有限 4,278,190,080 个，O≠N 864,018,432 个，**全部是负 0<|x|<2⁻²⁴**，其它 0；落在 WMMA 域（0 或 |x|≥2⁻¹⁸）的 0 个。去掉 half 舍入（直接 F(x)）在域内有 1,032,066 个不同——舍入不能删。
- **GPU**（`probe_f.hip`＋`probe_f.cpp`，9070 真实指令、与模块同一编译器）：GPU 原式对 CPU 模型 0 处不符；O≠N 864,026,623 = 上述 864,018,432 ＋ 8,191 个 +NaN（低 13 位载荷，掩码成 +Inf→448，原式 NaN→−448）；域内 0 个（`probe.log`）。

## 2. 输入域

- contract（`split_ffn_fused_fp8_t8`）：hidden 是 `byte_F` 的 E4M3 字节 × FP8 权重字节，从 +0 累加——与 09-30 composite-quant 同一证明：0 或 2⁻¹⁸ 的非零倍数，有限。
- mix（`split_mix_blocked_h16w_m32`）：f16 WMMA，但输入是 C512 块输入＝F 的输出（块 23 来自 Down `mh_pool_project_group_c256` 的 F(acc)，块 40 来自 Up `decoder_project2x_h16w` 的 F(merged)，其余是上一块 post 0 的 F(Hrtz)），都是 E4M3 值（2⁻⁹ 格点，|v|≤448）；half 权重 16 个 C512 块（23–30、40–47）实测最小非零位 2⁻⁹（最小 |w| = 2⁻⁹，无 half 次正规）。乘积是 2⁻¹⁸ 的倍数，同样落在域内。**这一条依赖权重数据**（打包资产 `block*-ffwd.f32` 前 262144 个值转 half 后的最小位），换权重要重核。补齐行（900 档 1500→1504）是池里垃圾，但只流向补齐行（shift-pack 已证）。
- ViT：`vit_*` 里的 `F(Hrtz(acc*inv))` 输入乘过 inv，不是纯 WMMA 和；vit_stream 无 `Hrtz` 出口。**ViT 不做**。

## 3. 逐位与计时（base = 装 c256-w16 后的现装 31 模块＋benchmark-P〔现装 add-on 源〕，候选只换两个 gfx1201 模块）

- 宏 0 编出的两模块与现装两架构 `.note/.rodata/.text` 同；配方直编 final 与实测 M 同。
- 7 用例 × EXACT/AE × 12 帧＋AE CSV＋900/1080 回绕：19 组 SAME（`full-M.log`）。

| 轮 | 900 avg（p99） | 1080 avg（p99） |
|---|---|---|
| 1 | 7.7822→7.7534，**−0.029**（8.018→7.985） | 10.6699→10.6524，**−0.018**（10.997→10.936） |
| 2 | 7.8054→7.7942，**−0.011**（8.029→8.019） | 10.6788→10.6692，**−0.010**（10.956→10.968） |
| 3 | 7.8126→7.8008，**−0.012**（8.058→8.056） | 10.6783→10.6728，**−0.006**（10.963→10.992） |

6 个 avg 全负；p99 900 每轮更好，1080 单轮来回跳，三轮平均 10.972→10.965 不差。收。900 第 1 轮比预估（0.003～0.005ms）大，多半是噪声，按三轮看约 −0.01～−0.02ms。

## 4. 装机

- 剑星、鬼武者：只换两架构 c512-m32-deep（gfx1201 6FC2F5BE / gfx1200 81183833）、deep_fast-packed（2764240B / D9109ADD），重建 SHA256SUMS（62）；add-on bb7ebfd1、RE9 runtime 88b59744、flags 不变。备份 `D:\DLSSNR-Lab\hip-backend\composite-quant-c512-20260930\backups\stellar-20260930-113745-c512mask`、`D:\DLSSNR-Lab\onimusha-backups\20260930-113745-c512mask`。RE9 runtime 只加载模块，接口不变，不重编。没发包。

复现：`Development/HIP/experiments/composite-quant-c512/`（cpu_proof_f.c；probe.ps1＝probe_f.hip＋probe_f.exe；setup → build-all → run-M → final → install）。lab `D:\DLSSNR-Lab\hip-backend\composite-quant-c512-20260930`。

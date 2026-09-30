# F/往返/精确除法清理扫全网（2026-09-30）：扫出 5 组，全部穷举通过、全部逐位；只收 deep_fast-packed

**结论**：把 c512-av-f 的三种清理（`fp8(F(x))`→`fp8(med3(x+0))`、精确除法→有界倒数、f32↔f16 往返）扫遍现装 31 模块。还能动的只剩 5 处，分属 4 个模块组，每组一个宏（源码默认 0）。4 组都证明通过、19 组 SAME；按新规只有 **D（deep_fast-packed）** 两档三轮全负、合并 p99 更好，**收下并装机**。V/M/W 两档里都有变慢的轮次，不收（宏留在源码，默认 0）。

## 1. 扫描结果（按"每帧次数 × 省下指令"排；µs 为 kernel-map-v3 900 档）

|组|位置|核（900 µs，次数）|输入域|处理|
|---|---|---|---|---|
|D|`deep_fast.hip` `byte_F`＋decoder `cvt_pk(F(merged))`|split_ffn_fused_fp8_t8（184，13）、vit_expand_blocked_fp8_frag_bytein（174，8）、vit_attention_fused_400/640（118/477@1080，8）、decoder_project2x_h16w_byteout（35，1）|任意 float（v·poly、Hrtz(acc·inv)，可下溢成 −0），所以用 `+0` 而不是直接删|`HIP_BYTE_F_ADD0`|
|D|ViT attention `1.f/sum`|vit_attention_fused_*（每 lane 1 次）|sum = ≤640 个 half 概率 [0x1c20,0x3e90]=[0.00403,1.64] 之和 ⊂ [1/256,2048]，有界|`HIP_VIT_ATTN_RCP`（rcp＋两步 Newton）|
|V|`vit_stream.inc` QKV 出口 `byte_F(v)`|vit_stream_qkv_frag_hin_w5（204，8）|任意 float（acc·rsq·scale）|`HIP_BYTE_F_ADD0`|
|M|`multihead_fast_padded.hip` `q8_fused_round`|mh_ffn_fused_c256_frag_project_mapped_g128_*（196，4）|任意 float|`HIP_Q8_ADD0`：`a==0?0:q8(med3 x)`→`q8(med3(x+0))`|
|W|`wave_owned_mh.inc` up 字节 `cvt_pk(w2_up_F(merged))`|c64/c128_wave2_up（116/83，各 1）＋swin-persistent|任意 float|`W2_UP_ADD0`|

扫到但不做：
- **float 出口的 F**（split_mix/contract、mh_attention_project_frag_c512 的 post、W2 float post、C32 finish/down、vit-stream `F(H(total))`、c512-m32-deep）：F 就是量化本身，删了值会变。
- **输入侧的 F**（`F(skip)*w`：deep_fast decoder、`w2_up_F(skip)`、`cw_up_F`）：要证明 skip 已在 F 格点上且零符号不影响 `t+(±0)·w`，证不出，跳过记账。
- 已做过：C512 compact（c512-av-f）、W2 `W2_BOUNDED_RCP`、W2/C512 复合量化掩码、C32 的 f16 往返与 `fp8(F)→+0`（CW_INPUT_HALF、prefix/finish 尾）。
- `c512_m32_mh.inc`/`c512_qkv_attention_fused.inc` 里的 `q8(F())` 所在核不在派发里（C512 只派 compact）。

## 2. 证明（gfx1201，模块同编译器；宿主复用 c512-av-f 的 probe_z.exe / probe_r.exe）

- `probe_a.hip`：`cvt_pk(F_branchless(x))` 对 `cvt_pk(med3(x+0))`，全部 2³² 位型（含 NaN/Inf/次正规）**0 处不同**（log 里的 "QKV ... diff=0" 那行；标签沿用宿主）。覆盖 D、V、W（w2_up_F 与 deep_fast 无分支 F 同一定义）。
- `probe_b.hip`：`q8_fused_round`（med3 版）对 `q8(med3(x+0))`，2³² **0 处不同**。覆盖 M。
- `probe_r2.hip`：[1/256, 2048] 内全部 float（[1/256,624] 144,441,345 个＋[624,2048] 同批检查）rcp＋两步 Newton 与 `1.f/x` **0 处不同**。
- ISA（D，gfx1201）：静态指令 72963→67189；decoder_byteout −364、vit_expand −314/−317/−700（m1/m2/m4）、split_ffn_t8 −241、vit_attention_400/640 各 −105（div_scale/fmas/fixup 全删，剩 1 rcp＋4 fma）。t8/expand 的 fma 条数不变（32/64），`+0` 没被并进乘法。
- 宏 0 编出的四个模块与现装 .note/.rodata/.text 相同（compare-modules.py）；配方直编的 final 与实测 D 代码相同。

## 3. 逐位与计时（base = 现装 31 模块＋现装宿主源；候选只换 gfx1201 对应模块）

每组 7 用例 × EXACT/AE × 12 帧＋AE CSV＋900/1080 回绕：**4 组都是 19 组 SAME**。ABBA 1000 帧弃 200，avg Δms：

|组|900 三轮|1080 三轮|判定|
|---|---|---|---|
|**D**|−0.038 / −0.030 / −0.014|−0.018 / −0.011 / −0.028|**收**；合并 900 7.6659→7.6388（p99 7.901→7.878），1080 10.5028→10.4836（p99 10.814→10.790）|
|V|+0.003 / +0.004 / +0.004|−0.014 / −0.014 / −0.008|不收（900 三轮都慢）|
|M|−0.009 / −0.010 / −0.022|+0.009 / +0.007 / +0.015|不收（1080 三轮都慢）|
|W|−0.004 / +0.013 / +0.007|+0.004 / +0.004 / +0.008|不收|

只收了 D 一组，不需要再做合并确认（D 的三轮就是对现装的确认）。

## 4. 装机

剑星、鬼武者只换两架构 deep_fast-packed（gfx1201 EEC7D4A6 / gfx1200 54D388A7），重建 SHA256SUMS（62）；add-on 6d059845、RE9 runtime 5e601d57、三个 flags 不变（RE9 runtime 不含模块，不重编）。备份 `D:\DLSSNR-Lab\hip-backend\f-sweep-20260930\backups\stellar-20260930-155252-fsweep`、`D:\DLSSNR-Lab\onimusha-backups\20260930-155252-fsweep`（含 `_storage_` runtime）。没发包；逐位帧转储 21.1GB 已删。

复现：`Development/HIP/experiments/f-sweep/`（probe_a/b/r2.hip、probe.ps1；setup → go/goW → final → install）。lab `D:\DLSSNR-Lab\hip-backend\f-sweep-20260930`。注意 swin-persistent 编译要把 `Development/HIP/swin_persistent_types.h` 放进 src.zip。

# C512 QKV-attention 去 F()＋有界倒数（2026-09-30）：证明成立，逐位，两档三轮全正，收下并装机

**结论**：`c512_qkv_attention_compact`（900 第二热点）里三处可以逐位删：AV 出口 `c5c_fp8(c5c_F(av))`→`c5c_fp8(av)`；QKV 出口 `q8(F(acc*inv))`→`q8(med3(acc*inv+0))`（`+0` 把 −0 变 +0，与 F 效果相同，mul 与 add 之间关闭乘加合并）；softmax 的 `1.f/sum` 从 IEEE 除法序列换成 rcp＋两步 Newton（c32 的 `norm_inverse`）。宏 `C512_COMPACT_NOF`、`C512_COMPACT_RCP`（`hip/c512_qkv_attention_compact.inc`，源码默认 0，c512-m32-mh 配方两个都写 1）。只换 c512-m32-mh，宿主和 runtime 不变。本核静态指令 1932→1545。

## 1. 为什么多余

- F(x) = `|x|==0 ? +0 : fp8值(clamp(x,±448))`，c5c_fp8/q8 最后得到 E4M3 字节。一个 fp8 值再做一次量化，得到的还是同一个字节，所以 fp8(F(x)) 和 fp8(clamp x) 只在 x=−0 时不同（F 输出 +0，得到字节 0x00；直接量化得到 0x80）。
- **AV**：av 是 4 次 FP8 WMMA 从 `f8{}`（+0）开始的累加。按 IEEE 规则，全是 −0 的乘积加上 +0 结果是 +0，完全抵消时 RNE 也给 +0，所以结果不会是 −0。V 字节**可以**是 0x80（上游 F 对负的微小数给出 −0），GPU 探针也覆盖了这种情况。
- **QKV**：acc·inv 可能是 −0（比如 scale 为负、acc=+0），所以 F 不能直接删；换成 `+0` 后，所有输入都相等。
- **倒数**：64 个指数值在 [2⁻¹⁴, 9.75]，所以 sum ∈ [1/256, 624]，落在 09-19 c32 已穷举过的区间。

## 2. 穷举

- CPU（`cpu_proof_z.c`，全部有限 x，fp8 RNE 饱和模型）：AV 不同 1 个（x=−0），QKV(x+0) 0 个。
- GPU（`probe_z.hip`，模块同编译器，gfx1201，2³² 个位型，包括 NaN/Inf/次正规）：CPU 模型对 GPU 0 处不符；AV 只在 −0 处不同；QKV `q8(F(x))` 对 `q8(med3(x+0))` 0 处不同（`probe.log`）。
- WMMA 零的符号（`probe_w.hip`）：P·V 四连 WMMA，V 取全 −0、±0 混合、±次正规抵消、任意字节，P 取 ≥+0，共 8.6×10⁹ 个结果：−0 为 0 个，+0 为 4.29×10⁹ 个（`probe-w.log`）。
- 倒数（`probe_r.hip`）：[1/256, 624] 内 144,441,345 个 float 全部与 `1.f/x` 逐位相同。
- ISA 检查：候选模块里没有把 mul 和 +0 合并成 fma 的指令（fma 条数 46=46）；compact 核的 div_scale/fmas/fixup 全部删掉，只剩 8 条 v_rcp。

## 3. 逐位与计时（base = 现装 31 模块＋现装宿主源 benchmark-base；候选只换 gfx1201 c512-m32-mh）

宏 0 编出的模块与现装模块 .note/.rodata/.text 相同；配方直编的 final 与实测模块代码相同。7 用例 × EXACT/AE × 12 帧＋AE CSV＋900/1080 回绕：19 组 SAME。

|轮|900 avg（p99）|1080 avg（p99）|
|---|---|---|
|1|7.6673→7.6397 **−0.028**（7.894→7.872）|10.5152→10.4875 **−0.028**（10.840→10.787）|
|2|7.6898→7.6716 **−0.018**（7.914→7.915）|10.5384→10.5153 **−0.023**（10.853→10.838）|
|3|7.7145→7.6851 **−0.029**（7.942→7.910）|10.5683→10.5341 **−0.034**（10.884→10.855）|
|合并|7.6906→7.6654，p99 7.920→7.900|10.5407→10.5123，p99 10.862→10.836|

两档 6 个 avg 全负，合并后的 p99 两档都更好，按新规收。三处改动的收益没有分开测。

## 4. 装机

剑星、鬼武者只换两架构 c512-m32-mh（gfx1201 0F28A38C / gfx1200 3BDB80CC），重建 SHA256SUMS（62）；add-on 6d059845、RE9 runtime 5e601d57、三个 flags 不变。备份 `D:\DLSSNR-Lab\hip-backend\c512-av-f-20260930\backups\stellar-20260930-150412-avf`、`D:\DLSSNR-Lab\onimusha-backups\20260930-150412-avf`（含 `_storage_` runtime）。没发包，逐位帧转储已删。

## 5. 本核余项

只剩同一个核里的 F/往返：prob 的 `c5c_fp8(ex*inv)` 没有 F；exponent 用位操作直接构造 half，也没有往返。这类冗余已经清完。

复现：`Development/HIP/experiments/c512-av-f/`（cpu_proof_z.c；probe.ps1/probe-w.ps1/probe-r.ps1；setup → go → final → install）。lab `D:\DLSSNR-Lab\hip-backend\c512-av-f-20260930`。

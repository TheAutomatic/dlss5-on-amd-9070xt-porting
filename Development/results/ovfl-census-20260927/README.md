# ACO follow-ups: FP16_OVFL census, paired fp8 unpack, v_pk_f16, DF_PACK8 (2026-09-27)

Continuation of `results/aco-isa-20260927` and `results/fmed3-ovfl-20260927`. 9070 (gfx1201), harness
`Development/HIP/experiments/pack8/` (7 cases × 12 frames RGB hashes, 1000-frame ABBA), baseline = set M (production recipe).

## 1. Segmented FP16_OVFL (W2_PACK8 4 = set O / P): census and decision

**Census probe** `W2_PACK8 5` (`hip/wave_owned_mh.inc`, never production): as the M clamp, but any pack input that is
non-finite (`W2_CENSUS_T 0`) or has |x| > T becomes 123.0. A set that stays bit-identical to M proves no such input reached a
C64–C256 fragment pack on the corpus. `hip/build-modules.ps1` now lets an `-ExtraDefines` macro override the recipe's value of
the same macro (default build unchanged).

| Set | Probe | 7 cases vs M |
|---|---|---|
| CNF | non-finite | all SAME |
| C448 | \|x\| > 448 | **all SAME** |
| C1 (positive control) | \|x\| > 1 | changed at the first case (probe is live) |

So on the corpus every C64–C256 pack input is finite and within ±448: the clamp never fires there, and the nearest failure
(f16 overflow, 65504) is ≥146× away.

**Why the inputs are finite (theory).** Every value reaching a W2 pack is an f32 result of WMMA accumulation over finite E4M3 /
f16-valued operands (|product| ≤ 448·65504, K ≤ 1024: far inside f32), RTZ f16 roundings (`Hrtz` = `v_cvt_pkrtz`, which
saturates instead of producing Inf), the guarded `rsq(max(ss, 6.2e-5))`, and `1/(Σexp)` with Σ ≥ 1 after max subtraction. The
operand bytes come from our own packs, which all clamp (NaN → −448), so no E4M3 NaN byte exists in the stream. The only
remaining Inf source is an RNE f16 narrowing (`H()`) in a chain-head producer (pool/Up) overflowing 65504 — not observed, and the
pack inputs never exceed 448 on the corpus.

**Timing** (P = recipe M + `W2_PACK8 4`, code-identical to the earlier O set 29/29 by `hip/compare-modules.py`; differs from M
only in c64-wave2), two ABBA batches:

| Tier | batch 1 M → O | batch 2 M → O |
|---|---|---|
| 900 | 9.672 → 9.620 (−0.051) | 9.792 → 9.744 (−0.048) |
| 1080 | 13.472 → 13.387 (−0.086) | 13.505 → 13.417 (−0.088) |

≈ −0.5% / −0.65%. **Candidate, installed in Stellar Blade (deployments/ovfl-20260927), not yet in the production recipe**: the
only behavioural difference from M is ±Inf/NaN at a pack (E4M3 NaN byte instead of ±448); adopt after Zero's in-game check.

The "keep a guard only for non-finite values" alternative does not pay: med3 is already one VALU per value, and any per-value
class test / select is ≥ 1 VALU; a word-level NaN-byte check after packing costs ~1 VALU per value plus a branch.

## 2. ACO candidates 3/4

- **Paired unpack `v_cvt_pk_f32_fp8`: not usable on gfx1201.** Probe `Development/HIP/experiments/pair-unpack/probe2.hip`
  (word 0xc4054038 = bytes 1.0, 2.0, 0x05, −3.0): the instruction returns **(byte0, byte0)** and with `op_sel:[1,0]`
  **(byte2, byte2)**, both via inline asm and `__builtin_amdgcn_cvt_pk_f32_fp8`; single `v_cvt_f32_fp8 byte_sel:n` is correct.
  ACO emits exactly this instruction in mochizuki's fswin64 (64 per window), so either their driver differs or their unpacks
  duplicate a byte (worth telling them). Also: the byte round trip q8(cvt_f32_fp8(b)) is the identity for all 256 bytes except
  0x7F (NaN) → 0xFF.
- **v_pk_*_f16 instead of f32 op + narrow:** the f16 sites in C64/C32 are `Hrtz` round trips (RTZ); `v_pk_*_f16` rounds by MODE
  (RNE), so equality needs the f16 rounding mode switched to RTZ per segment plus f16-packed weights, for < 1 VALU per value. Not
  done.

## 3. Why DF_PACK8 did not pay (C512 / ViT)

Most `DF_PACK8_LOOP` sites are in branches production does not take (the ViT expand reads bytes from `vit_pack_input`; the
paired pack there already exists). The live ones are f32-input kernels such as `vit_project_frag_n64` (static: VALU 1097, WMMA 64,
**VMEM 164**; each 16×16×16 step reads 8 f32 = 32 B per lane per fragment and the input is re-read once per 64-column tile) —
memory-bound, so fewer VALU does not show. ACO's gemm kernels read E4M3 activations written by the producer (`NR_OUT_E4M3`).
Our equivalent, the ViT byte stream (`vit_byte_stream`, producer-side packing, bit-exact by construction), exists but is mutually
exclusive with adaptive ViT reuse; left as a candidate (WorkingPlan).

## Files
- `hip/wave_owned_mh.inc` (W2_PACK8 5 census probe), `hip/build-modules.ps1` (extra defines override the recipe)
- `Development/HIP/experiments/pack8/build.ps1` (sets CNF, C448, C4K, C64K, C1, P)
- `Development/HIP/experiments/pair-unpack/` (probe.hip/.cpp, probe2.hip/.cpp)
- `Development/deployments/ovfl-20260927/` (install/restore)

# Daniel activation/packing audit (2026-09-28)

Candidate patch: `/tmp/daniel-kernels/candidate.patch`, fresh worktree HEAD `21fc931`.
One candidate, default-off `W2_PACK_NOZERO=1` for module `c64-wave2` (recipe W2_PACK8=6).
No GPU, compilation, timing or bitwise result claimed.

## Evidence

- Daniel reference C64 `/tmp/fma-vs-nvidia/daniel-c64.s`: address 0x10CBE4 writes low half of v49 with `v_cvt_pk_fp8_f32`; 0x10CDD4 overwrites high half with op_sel:[0,0,1]. v49 was a packed-half activation immediately before this: no dependency on zeroed destination.
- Our PRE-FLOAT-FMA ISA `/tmp/aco-lineup/R-mh.s`, `c64_wave2_bi_bo`, lines 160781–160787: dual mov v36/v37 to zero, two low-half conversions, two high-half conversions. Clear is dead at word level once both halves are written. Confirm this persists in current float-FMA build before attributing savings.
- Existing production `hip/wave_owned_c32.inc::cw_pack8` already expresses the complete two-word conversion as one inline ASM output group, with early-clobber output operands and no incoming destination. Candidate copies this structure for W2.
- Prior ACO audit's activation table: 64 zeroing scalar slots per 256 C64 activation values (typically 32 VOPD instructions). This is an old analytical count, not a measured new-build saving. Other W2 packing sites may also benefit.

## Preserved arithmetic

`w2_z` remains applied to all eight inputs. Mode 6 retains callers' product FMA(+0) / zero-canonicalization rules; mode 4 retains its add-zero. Four FP8 conversions still use the same saturation mode, operand order, rounding and low/high-half selection. Float FMA activation and final product are untouched. Other W2_PACK8 modes remain original. The block may alter register lifetime or scheduling; bitwise corpus and resources must be checked before adoption.

## Not candidates

Daniel's half FMA/packed-half activations, normalization trees and corrected division are numerically different, not instruction-equivalent simplifications. No inferred count saving from those is included. No evidence sufficient to justify a second address/dynamic-index patch emerged in this bounded audit; C256 scalar quantization is real but its existing pair variant and producer-layout constraints require their own current-ISA check.

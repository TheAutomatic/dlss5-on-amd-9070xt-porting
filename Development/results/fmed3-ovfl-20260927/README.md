# fmed3 clamps and segmented FP16_OVFL on top of pack8 (2026-09-27)

Direction from the ACO comparison (`results/aco-isa-20260927`): the E4M3 conversions cost ~4.5 VALU per byte, part of it a
`v_max_num_f32 x,x` canonicalisation LLVM puts in front of every `fminf/fmaxf`-derived `v_med3` (IEEE mode quiets sNaN).
Experiment sets through `Development/HIP/experiments/pack8/build.ps1` (9070, gfx1201; regression = the 7-case × 12-frame
RGB hash check and 1000-frame ABBA of `regression.ps1`).

| Set | Defines | c64-wave2 ISA (total / VALU / med3 / `max x,x`) | 7 cases | Timing |
|---|---|---|---|---|
| A | defaults (0.32 recipe) | 213627 / 125561 / 9109 / 2345 | — | — |
| Z | CW_PACK8, W2_PACK8 2 | 191694 / 108479 / 9558 / 1826 | same | reference below |
| N | Z + HIP_FP8_SAT_MODE 3 (C32 med3) | c32-wave1 40813→40171, `max x,x` 460→76 | same | — |
| **M** | N + W2_PACK8 3 + **HIP_FMED3_CLAMP 1** | 189212 / 106816 / 10370 / **84** | **same** | vs Z: 900 −0.025/−0.052, 1080 −0.069/−0.082 ms (≈ −0.5%) |
| O | M with W2_PACK8 4 (segmented MODE.FP16_OVFL around each fragment's 4 converts, no clamp) | 187453 / 103311 / 6706 / — (+916 s_setreg) | same | vs M: 900 −0.049/−0.057, 1080 −0.063/−0.082 ms |

- `HIP_FMED3_CLAMP` (`hip/multihead_fast_padded.hip`): `clampf`, `F()`, `q8_fused_round` and the paired converts spell the
  clamp as `__builtin_amdgcn_fmed3f`, which needs no canonicalisation. Same result for every non-NaN input, NaN → lo in both
  forms. W2_PACK8 3 alone compiled to the same code as 2; the canonicalisations came from those shared helpers.
- **M is the next production recipe** (`hip/build-modules.ps1`): c32-wave1 `CW_PACK8 1, HIP_FP8_SAT_MODE 3`; c64-wave2
  `W2_PACK8 3, HIP_FMED3_CLAMP 1`; c512-m32-mh and multihead-fast-padded-wave(-packed) `HIP_FMED3_CLAMP 1`;
  c32_fused_ffn_attention(-packed) `HIP_FP8_SAT_MODE 3`. The default build equals set M code-for-code (29/29,
  `hip/compare-modules.py`); hashes of both architectures in `next-modules-sha256.txt`. This build also recompiles the three
  fallback modules from source (WorkingPlan A5).
- **O is not adopted yet**: bit-exact on the corpus and another ≈0.5%, but for ±Inf/NaN inputs the saturating convert gives
  the E4M3 NaN byte where the clamp gave ±448 / −448 — exactly the guard the 0.10 black-block fix relies on if an f16
  overflow ever reaches a C64 pack. Needs an Inf/NaN census on more inputs (or a clamp kept only for the non-finite case)
  before production.
- `Development/HIP/validate-modules.ps1` could not run: its default asset folder (`network-720p`) no longer exists on the 9070.

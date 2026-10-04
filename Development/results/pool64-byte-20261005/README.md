# block4 pool → first C64 typed FP8 edge — preliminary exact gate

Base: knife1 `76750a80`. Only producer kernel source changes; shared host is owned by build_install.

New `mh_pool_project_c32_b8_out8` preserves both WMMA steps, Hrtz and F; stores `q8(F(acc))` instead of float. It does not delete F/Hrtz, change K/reduction order, or impose a new quantization. Original raw ±0 is preserved by the stored FP8 sign; first-C64 staging canonicalization remains consumer-owned, while residual decoding uses original bytes.

CPU check covers only unique binary32 representations of 254 finite E4M3 codes, including both zeros. Native GPU proof covers all 65536 half bit patterns (including NaN/Inf): original `F(Hrtz(raw))` versus decoding the stored byte, zero bit differences.

Real block4-ds plus block5-ffn/attention weights: 400×240, 480×288, 640×368 and 17×19 tail geometry, each with three dynamic finite byte patterns; all 12 two-kernel output comparisons have zero byte differences. Existing production `c64-wave2-fast` non-W16 fragment kernels are used: release041 has no C64 W16 exports because `W2_FFN_W16_SMALL` defaults to 0. No consumer module is rebuilt.

MP1/PRED0/SKIN0/FAST1; independent owner lock, no running game, D free≥100GB, 15s probe-only watchdog. GPU released. No performance claim yet; whole-network screen belongs to build_install. The probe module contains extra proof export and must be rebuilt without `proof_kernels.inc` before production acceptance.

Initial batch was diagnostic only: prepare omitted canonical HIP_ISA_HALF/HIP_PREPACKED_WEIGHTS. Its logs/metadata are retained under `diagnostic-noncanonical`; do not use it for production correctness or performance. Canonical corrected batch follows.

Raw logs: `probe.log`, `probe.err`; source recipe metadata: `source-proof.json`. Corrected canonical GPU module SHA256: gfx1201 `d27cb16a7eeacdb6d75aa16094fcac4254971287fe6c45c6202bd2451fdb9d16`; gfx1200 `bdb0573fd2aa1c33ccd4c815f3b9714cc61e74ae5431ec184f90739b340d5765`. Both ELF targets verified from downloaded headers (`0x48` gfx1200 / `0x4e` gfx1201), see `module-metadata.json`. Corrected full-prefix source metadata is `source-proof.json`: `HIP_ISA_HALF 1`, `HIP_PREPACKED_WEIGHTS 1`, then exact row defines; row opts empty and inherited RTC_EXTRA_OPTS cleared. RTC: release041 payload, COMGR compiler, explicit target argv. Canonical corrected run repeated 65536-half and all 12 actual pairs with zero differences. GPU lock released. No GPU event timing used.

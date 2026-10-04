# block4 pool → first C64 typed FP8 edge — preliminary exact gate

Base: knife1 `76750a80`. Only producer kernel source changes; shared host is owned by build_install.

New `mh_pool_project_c32_b8_out8` preserves both WMMA steps, Hrtz and F; stores `q8(F(acc))` instead of float. It does not delete F/Hrtz, change K/reduction order, or impose a new quantization. Original raw ±0 is preserved by the stored FP8 sign; first-C64 staging canonicalization remains consumer-owned, while residual decoding uses original bytes.

CPU check covers only unique binary32 representations of 254 finite E4M3 codes, including both zeros. Native GPU proof covers all 65536 half bit patterns (including NaN/Inf): original `F(Hrtz(raw))` versus decoding the stored byte, zero bit differences.

Real block4-ds plus block5-ffn/attention weights: 400×240, 480×288, 640×368 and 17×19 tail geometry, each with three dynamic finite byte patterns; all 12 two-kernel output comparisons have zero byte differences. Existing production `c64-wave2-fast` non-W16 fragment kernels are used: release041 has no C64 W16 exports because `W2_FFN_W16_SMALL` defaults to 0. No consumer module is rebuilt.

MP1/PRED0/SKIN0/FAST1; independent owner lock, no running game, D free≥100GB, 15s probe-only watchdog. GPU released. No performance claim yet; whole-network screen belongs to build_install. The probe module contains extra proof export and must be rebuilt without `proof_kernels.inc` before production acceptance.

Raw logs: `probe.log`, `probe.err`; source recipe metadata: `source-proof.json`. Full GPU module SHA256: gfx1201 `d0dd562efccc9504e4d07be99620927a7ebe71bc2d583c9db0f75f6b5547813b`; gfx1200 `a3ecfba3581eb06e5507a149e74b51c746dc044df78d28de636c703fdc0abbca`. RTC: release041 payload, COMGR compiler, explicit target argv. No GPU event timing used.

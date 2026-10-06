# CPU causal boundary: QB32 half-math versus locked PAL VT

Both are one32-lane wave with two16-query blocks: HIP generated new.hip466–481 Q0/Q1; M vit_attn.comp129–136 NR_QT32/NR_VWAVES1/NR_QB2; actual cache14.notes threadgroup32×1×1. WG2-wave is not a difference. Both shareK/V between query blocks, QK/AV accumulators F32.

Three remaining material differences:

1. Supply/layout: HIP new.hip470–479 has Q/K8-byte contiguous AoS reads and V16 scalar-byte gathers/packing, three640×1024 planes. M vit_attn.comp nr_at16 and VTchunk26–38 have blocked16×16 tiles, interleaved QKV X3=3072; actual PAL0x29c/0x2a8 loads2TR_b64, then0x840/84c and0x91c/924 reuseV for bothquery tiles. Main COMGR8d5 hasTR0. Sharedquery count alone does not replicate this supply.

2. Final numeric contract: HIP new.hip480–483 uses FP32vit_inv and F32context product→FP8 (FAST1 half wrapper identity); M comp813 casts context/inverse/product toF16 beforeFP8, PAL3480cvt_f16/3490mul_f16 and remaining tail confirm actual half operations. Score/den64 match intended half representation, not every attention operation.

3. Actual dispatch scope: HIP host hip_reference_network.h658 passesn*512;38132threads/zeroexplicitgroups,431fallback(count+255)/256 yields1280groups at640tokens. Newfirst=bid()/32*32 =>640live groups and640uniform earlyreturns. M lockedQT32 geometry emits20querytiles×32heads=640live groups. This is work-count fact, not a timing attribution.

These prevent treating HIP combination STOP as a direct M mathematics ablation. M-side singlevariant that changes onlyscore/den toF32 while retainingQB2/layout/TR/exit is a cleaner local causal comparison, still not a complete gap explanation. No occupancy/ms claim, new experiment, or GPU work. Artifacts: /tmp/vit-m32-halfmix-20261006/new.hip; /tmp/vit-m32-halfmix-comgr-20261006/new-640.isa; /tmp/mochi-pipeline-map-20261006/vitattn.isa; locked Linuxvit_attn.comp/include/vit_attn_vt_chunk.glsl.

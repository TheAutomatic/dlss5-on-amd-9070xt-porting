# Native1440 C256 persistent FAST3 — preliminary exact gate

Base: knife2 `9bbd3749`. Production change here is only a new `swin-persistent-fast` recipe row: normal persistent row plus `W2_FAST_NUM 3`. Canonical `compile-modules.py.recipe()` generates complete ISA_HALF/row PREPACKED prefix and synthetic types. Empty row opts, COMGR21, explicit gfx1200/gfx1201; downloaded ELF headers verified `0x48` / `0x4e`. No new scalar helper, K ordering, FP8/H rounding, or queue algorithm.

CPU independent rectangle-intersection oracle matches SpGetPlan child formula for 100×60, 120×72, and 160×92: every real pixel exactly one producer window, all next-window reads covered, no empty node, parent/child degree1..4. Native1440 encoder16..21 and decoder49..54 have shifts3/1/2/0/3/1; tasks252/252/240/240/252/252=1488 per stage, initial252, state17872 bytes.

GPU segment probe uses production real weights and finite dynamic FP8 byte inputs. Baseline is six sequential `c256_wave2_bi_bo_w16` kernels from release041 c64-wave2-fast (FAST3, independent token batch4). Candidate is six-layer SP-fast (FAST3, independent token batch2); each accumulator keeps its original kt/ht WMMA and arithmetic order. Both encoder and decoder compare zero output byte differences for normal execution, forced queue timeout with serial recovery, and ticket rollover: six comparisons, recovery2, rollover2, jobs8928. This is actual segment exactness evidence; not yet whole-network acceptance or speed evidence.

MP1/PRED0/SKIN0/FAST1, owner-exclusive GPU lock, game check, D≥100GB, 15-second probe-only watchdog. GPU released. Existing 900/1080 SP normal routing must remain unchanged. New1440 FAST1 requires the fast module/run/recover pair; missing module/exports must revert the complete stage to existing Body. FAST0 may use original SP normal. Host gate/loader and whole-performance screen are owned by build_install, outside this commit.

Artifacts: `plan-proof.json`, `probe.log`, `probe.err`, full source recipe `source.json`, module hashes/targets `modules.json`; scripts in Development/HIP/experiments/sp1440-fast. No game installation or release ZIP change.

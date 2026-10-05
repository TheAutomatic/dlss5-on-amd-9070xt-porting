# Native1440 C256 persistent FAST3 — preliminary exact gate

Base: knife2 `9bbd3749`. Production change here is only a new `swin-persistent-fast` recipe row: normal persistent row plus `W2_FAST_NUM 3`. Canonical `compile-modules.py.recipe()` generates complete ISA_HALF/row PREPACKED prefix and synthetic types. Empty row opts, COMGR21, explicit gfx1200/gfx1201; downloaded ELF headers verified `0x48` / `0x4e`. No new scalar helper, K ordering, FP8/H rounding, or queue algorithm.

CPU independent rectangle-intersection oracle matches SpGetPlan child formula for 100×60, 120×72, and 160×92: every real pixel exactly one producer window, all next-window reads covered, no empty node, parent/child degree1..4. Native1440 encoder16..21 and decoder49..54 have shifts3/1/2/0/3/1; tasks252/252/240/240/252/252=1488 per stage, initial252, state17872 bytes.

GPU segment probe uses production real weights and finite dynamic FP8 byte inputs. Baseline is six sequential `c256_wave2_bi_bo_w16` kernels from release041 c64-wave2-fast (FAST3, independent token batch4). Candidate is six-layer SP-fast (FAST3, independent token batch2); each accumulator keeps its original kt/ht WMMA and arithmetic order. Both encoder and decoder compare zero output byte differences for normal execution, forced queue timeout with serial recovery, and ticket rollover: six comparisons, recovery2, rollover2, jobs8928. This is actual segment exactness evidence; not yet whole-network acceptance or speed evidence.

MP1/PRED0/SKIN0/FAST1, owner-exclusive GPU lock, game check, D≥100GB, 15-second probe-only watchdog. GPU released. Existing 900/1080 SP normal routing must remain unchanged. New1440 FAST1 requires the fast module/run/recover pair; missing module/exports must revert the complete stage to existing Body. FAST0 may use original SP normal. Host gate/loader and whole-performance screen are owned by build_install, outside this commit.

Artifacts: `plan-proof.json`, `probe.log`, `probe.err`, full source recipe `source.json`, module hashes/targets `modules.json`; scripts in Development/HIP/experiments/sp1440-fast. No game installation or release ZIP change.

## 整网通过/安装

基线9bbd3749，保刀1/2。只2560×1472且FAST1使用同FAST3的SP-fast；FAST0/graph/缺twin或init-run-recover出口全旧Body，旧900/1080SPnormal不改。两plan构造期提前load/upload，热路径不增同步/模块加载。

1440 3round320弃80、1440samples/侧，三轮−.100548/−.093360/−.074219ms；合并墙钟16.322089→16.232713（省.089376ms）、p99 16.832→16.748，全部无慢轮。非FPS、不将三刀跨批相加。七组few RAW（旧900/1080、FAST0/缺twin/graph旧路、motion、预测history）全SAME；RE9 1440单遍/预测3各4帧SAME且swin1440_ready日志实际命中，smoke ok；段级正常/timeoutrecover/rollover六组已严格0diff，不重刷矩阵。

安装addon698a23a4ad9ac9eb3458761dc82058c1ea10f27e79456bac182c0f8f69aefbb0，runtime634faf4501c976c80d6cff9ff8eadaf4101ab40f7afa42882eeed54163089da4根/_storage相同。原76模块逐hash完全不变，仅增加双arch SP-fast成为78；三配置hash不变。备份D:\DLSSNR-Lab\sp1440-fast-20261005\backups\20261005-080146带rollback，exact同步、锁释放、原帧留hash后仅清实验输出。0.41已上传ZIP仍76，不改/不push/tag。gfx1200仅编/ELF，未硬件验证。

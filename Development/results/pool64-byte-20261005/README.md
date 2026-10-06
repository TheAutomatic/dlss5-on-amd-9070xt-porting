# block4 pool → first C64 typed FP8 edge — preliminary exact gate

Base: knife1 `76750a80`. Only producer kernel source changes; shared host is owned by build_install.

New `mh_pool_project_c32_b8_out8` preserves both WMMA steps, Hrtz and F; stores `q8(F(acc))` instead of float. It does not delete F/Hrtz, change K/reduction order, or impose a new quantization. Original raw ±0 is preserved by the stored FP8 sign; first-C64 staging canonicalization remains consumer-owned, while residual decoding uses original bytes.

CPU check covers only unique binary32 representations of 254 finite E4M3 codes, including both zeros. Native GPU proof covers all 65536 half bit patterns (including NaN/Inf): original `F(Hrtz(raw))` versus decoding the stored byte, zero bit differences.

Real block4-ds plus block5-ffn/attention weights: 400×240, 480×288, 640×368 and 17×19 tail geometry, each with three dynamic finite byte patterns; all 12 two-kernel output comparisons have zero byte differences. Existing production `c64-wave2-fast` non-W16 fragment kernels are used: release041 has no C64 W16 exports because `W2_FFN_W16_SMALL` defaults to 0. No consumer module is rebuilt.

MP1/PRED0/SKIN0/FAST1; independent owner lock, no running game, D free≥100GB, 15s probe-only watchdog. GPU released. No performance claim yet; whole-network screen belongs to build_install. The probe module contains extra proof export and must be rebuilt without `proof_kernels.inc` before production acceptance.

Initial batch was diagnostic only: prepare omitted canonical HIP_ISA_HALF/HIP_PREPACKED_WEIGHTS. Its logs/metadata are retained under `diagnostic-noncanonical`; do not use it for production correctness or performance. Canonical corrected batch follows.

Raw logs: `probe.log`, `probe.err`; source recipe metadata: `source-proof.json`. Corrected canonical GPU module SHA256: gfx1201 `d27cb16a7eeacdb6d75aa16094fcac4254971287fe6c45c6202bd2451fdb9d16`; gfx1200 `bdb0573fd2aa1c33ccd4c815f3b9714cc61e74ae5431ec184f90739b340d5765`. Both ELF targets verified from downloaded headers (`0x48` gfx1200 / `0x4e` gfx1201), see `module-metadata.json`. Corrected full-prefix source metadata is `source-proof.json`: `HIP_ISA_HALF 1`, `HIP_PREPACKED_WEIGHTS 1`, then exact row defines; row opts empty and inherited RTC_EXTRA_OPTS cleared. RTC: release041 payload, COMGR compiler, explicit target argv. Canonical corrected run repeated 65536-half and all 12 actual pairs with zero differences. GPU lock released. No GPU event timing used.

## 整网通过并安装

基线76750a80，刀1最终直写保留；新producer保q8(F(Hrtz(sum)))，真实C64是非W16，未启新SMALL。构造缓存pair/缺一旧路，Run明确32threads；模块canonical去proof，生产gfx1201 E452EEDB/gfx1200 1A7BF772且ELF正确。旧缺前缀batch只诊断，已重新正式proof/pair。

三档3round320弃80，1440samples/侧：900平均7.049135→7.036783（省.012353ms），p99 7.336→7.326；1080 9.875939→9.856327（省.019612），10.256→10.240；1440 16.411153→16.368044（省.043110），16.873→16.832。全部无慢轮；900第三轮仅−.0001125ms，属于近乎持平，不刷轮、不乘流量当FPS。

正常19真byte命中全SAME，1440预测history/900预测skin RAW、旧module缺export真回退、RE9 900单遍/1080预测3四帧和smoke通过。装剑星addon8547c07f826c4c8642d1672d822e0ff82e35d9675d8383c28a757dfbcb924500；鬼武者root/_storage runtime14bac9fadc31a29a8f7138d32552486f6658d7284991b1e10a9e42b989e3540b；单mh-fast-packed双arch及SUMS更新，配置字节不变、刀1保留。备份D:\DLSSNR-Lab\pool64-byte-20261005\backups\20261005-073426带rollback。exact同步，锁释放，原输出留hash后清理，仅本轮不删权重/输入；0.41上传ZIP不动，未push/tag。

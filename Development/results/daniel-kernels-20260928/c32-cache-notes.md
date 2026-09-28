# C32 weight supply candidate

Source base: dafba40; isolated worktree `/tmp/c32-cache-worktree`.
Patch: `/tmp/daniel-kernels/c32-cache.patch`.
Default-off `CW_WEIGHT_CACHE`: 1 = QKV, 2 = projection, 3 = both.

The QKV weight address depends on part/ci/kt/lane, not qt. Cache its 12 i2 fragments before the first four-qt loop. Projection caches four i2 before its four-qt loop. Separate lexical scopes avoid carrying QKV weights into the projection phase. Lane identities retain the original CW_QKV_FENCE / CW_LAUNDER treatment; no input/output restrict promises were added. Each cache entry is anchored as two scalar VGPR outputs using empty +v ASM, so compiler alias conservatism cannot legally replace its uses by new loads.

Potential direct weight loads per wave: QKV 48→12, projection 16→4 (assuming existing loop does issue every load and compiler honors retained cache). This is not a prediction for total VMEM or net speed: higher VGPR lifetimes, rematerialization, scheduling and occupancy need compiled ISA. QKV adds up to 24 live VGPRs, projection 8; not necessarily actual peak increases.

Daniel reference disassembly `/tmp/fma-vs-nvidia/daniel-c32.s` supports the general reuse strategy:
- 0x52C04 loads v29:30; QKV WMMA at 0x53DE0 and 0x542F4 reuse those unchanged registers with different input fragments.
- Final projection load 0x55D64 fills v21:22; four WMMA at 0x55F2C/34/3C/44 use it for different token fragments.
This is not a claim of copying Daniel's layouts or arithmetic. His half arithmetic stays excluded.

Only `git diff --check` run; no compilation or GPU execution here. Default=0 preprocessor output retains the original arithmetic and load locations. Parent will check resulting ISA, resources, numerical regression and speed.

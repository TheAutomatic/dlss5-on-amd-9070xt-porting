# Static seed0 prefix noise-field experiment

This is an isolated candidate, not a production switch or a claim that mochi's
noise values equal ours. Current full71 FAST1 900 GPU gap is0.600ms; mochi creates
its seed0 noise-field outside graph timing, while current C32 inline prefix
executes its Box–Muller every frame. The old zero-noise null was not this cache.

prepare.py mechanically extracts the current CW_PREFIX_SPLIT Gaussian operation
sequence. New GPU builder and original-domain gold use that sequence and RTZ
half bits. Cache layout is raster uint2=half4(g1,g2,g0,+0),8B/pixel; the cached
prefix keeps the original half-wave g0 exchange, mixed features, WMMA/K order,
RGB/history/style construction and downstream arithmetic. It never caches a
projected noise contribution or a complete prefix feature/output.

Conservative per-Network cache admission requires explicit caller exposure/reset
epoch, seed0, non-graph and non-history-experiment. Width/height and compiled
module are immutable instance identity; style/exposure float bits and reset epoch
invalidate the lease. Nonzero seed/invalid exposure/unprovided context fall back
to current noise computation. The persistent Tensor reference excludes the buffer
from pool reuse; release follows stream completion at destruction. RGB/history
remain freshly read even when seed0 noise is reused.

Memory/read traffic per warm frame:9001600×96012.288MB,10801920×115217.695MB;
7207.864MB,1088rows16.712MB,144030.147MB. More cache traffic can cancel savedSFU.
CPU static LLVM23:baseline128VGPR/cache127, both4KiB LDS/zero spill/private;
builder10VGPR/zeroLDS. Original log/sqrt/cos/sin static noise instructions vanish
in the cached prefix, WMMA48 remains; no new occupancy or speed claim follows.

build.py runs only local LLVM23 and MinGW CPU compilation. check_layout.py proves
all65536 binary16 payload packing including signed zero and the window→raster
permutation; it does not approximate Gaussian output or pretend to be a GPUgold.
run.ps1 acquires the existing atomic GPU lock, checks games/100GiB/15s watchdog,
and runs primitive half-domain and full-prefix main/down gold for FAST0/1, then
one FAST1 complete-network stock-vs-patched correctness slot and first ABBA.
No mid-frame image scanning; only timing events per frame and edge readbacks.

Do not expand after a negative screen or use primitive timing to explain the
whole0.600ms gap. No installation/config/0.41 or0.41-a archive change is authorized.

# multi-pass-20261003: DLSS5_MULTI_PASS (叠层)

Where: shared network layer `Development/HIP/hip_reference_network.h` (`Network::EnqueueRaw` → `MultiPassRest`), so the regular add-on,
the Magpie add-on and the RE9 runtime (whitelist in `src/LmxxfNrRuntime.cpp`) all get it. `1`/unset/empty = old path; other values → 1 + stderr.

Semantics (Magpie 0.6.8 DLSSNR Multi Pass: implementation not public, so "final output re-fed as input"): pass k+1's colour input = pass k's
final RGB (alpha 1.0), same history, seed, noise. The network output is already the clamped [0,1] picture in the input's working encoding
(post head = input RGB + residual), so decode→encode between passes is the identity and is skipped (the encode pass's RGBA16F rounding is not
repeated; the f32 output is fed as is). History: every pass reads the same frame history (simplest correct choice; nothing new is written
per pass). Feed = persistent RGBA f32 buffer(s), RGB copied with hipMemcpy2DAsync in 2^19-row chunks (Windows HIP silently caps at 2^20 rows).
Adaptive ViT reuse forced off while N>1. Graph mode captures all passes (feed allocated in the warm frame). `Infer()` (readback test path) is single pass.
GetTimings / net_gpu_ms / DLSS5_NET_TIMING = total of all passes.

Hosts: base = main 5f8c4212 benchmark (C6655E86); M = branch benchmark (16B3EB18). Modules = installed Stellar gfx1201 (SUMS F3EFDC16).

## Default (=1) bit-identity
- full.ps1 (19 groups incl. AE + rollover, -PinIdle): 19 SAME. Explicit `DLSS5_MULTI_PASS=1`: 7/7 SAME.
- Invalid 7 / 0 / abc: output = base (C3B23A3E), stderr "invalid (1/2/3), using 1".
- ABBA 3 rounds (option unset, M vs base): 900 −0.026/+0.043/+0.002, 1080 +0.021/+0.005/+0.003 ms; merged 7.074→7.080 / 9.806→9.815, p99 within 0.013 ms. Neutral (code-equivalent: N=1 runs the same calls).
- RE9 replay (rt_bench 1707x961, 12 frames, runtime E200E8A6 vs installed 838A8B97): 900 6f961945261a355c SAME, 1080 aaa31e2dffa3a1b5 SAME; reruns SAME; runtime-smoke exit 0.

## 2 / 3 passes
| | 900 avg ms | 1080 avg ms |
|---|---|---|
| 1 pass | 7.04–7.13 | 9.82–9.89 |
| 2 passes | 13.73 / 13.86 (+95%) | 19.51 / 19.51 (+97–98%) |
| 3 passes | 20.51 / 20.69 (+191%) | 28.99 / 29.02 (+195%) |

RE9 runtime: 900 7.02 → 13.80 → 20.55 ms, 1080 9.70 → 19.35 → 29.09 ms. Process VRAM (rt_bench): 900 1407 → 1435 → 1482 MiB, 1080 1380 → 1491 → 1491 MiB
(feed buffers W×H×16 B: 1080 tier 35.4 MB, 900 24.6 MB, 720 15.7 MB each, one for 2 passes, two for 3; rest is pool growth).
Reproducible: 7 cases × 12 frames run twice, 84/84 hashes identical for both 2 and 3; 0 non-finite halves. RE9 `DLSS5_MULTI_PASS=2` via env and via the flags
file give the same hash (whitelist works). Against the single pass (style change, not a loss): 2 passes 38.39–39.06 dB, 3 passes 34.18–34.71 dB.

## Screenshots
`shots/<case>-pass{1,2,3}.png` (frame 11 of 900-static, 1080-static, 1080-motion; harness preview size).

Scripts: `Development/HIP/experiments/multi-pass/`. Install: `Development/deployments/multi-pass-20261003/` (backup 20261003-102714).

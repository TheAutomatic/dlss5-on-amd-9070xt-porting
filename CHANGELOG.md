# Changelog

[中文](CHANGELOG.zh-CN.md) · The changelog table in the README is a one-line summary per release; this file expands each release: what changed, measured effect, switches, whether it is bit-exact, and the matching experiment folder. Oldest first; new releases are appended at the end.

Notes:
- "Bit-exact" means the fast chain's output is identical to the previous release (EXACT and AE). From 0.01 on, the exact reference chain is frozen as the judge; the fast chain is about 42 dB PSNR against it.
- "Offline" is the network-only bench (1000 frames, first 200 dropped). "900 tier / 1080 tier" means the network processes 1600×960 / 1920×1152. In-game numbers are Stellar Blade on an RX 9070 XT unless stated.
- Numbers that were not measured are not written. Experiments live in `Development/results/<folder>/`, the log in `Development/DevHistory.md`.

## Early releases (0.01–0.23)

Details are the matching rows of the README table; key points only.

| Version | Date | Key points |
|---|---|---|
| 0.01 | 09-08 | Exact port done: all 71 blocks on wave matrix kernels, 15 frames bit-identical to the original; bench 186 ms, about 5 fps |
| 0.02 | 09-08 | Fast chain starts (exact chain frozen as the judge): FP32 hardware accumulation, E4M3 operands; temporal inputs wired; 112 ms |
| 0.03 | 09-08 | Hardware f16/E4M3 conversion, fused QKV+norm, etc.; 62.7 ms, about 15 fps |
| 0.04 | 09-09 | Deferred submit ring, command-list batching, ALU noise prefix; 23–25 fps |
| 0.05 | 09-09 | Output temporal smoothing, FP8 ViT attention; 24–25 fps |
| 0.06 | 09-09 | Repo reorganised, GPU probes off by default, E4M3 pre-block output; 27–28 fps |
| (0.07) | 09-09 | Three blocks skipped (lossy, 40.7 dB), VRAM 6.8→3.75 GB; 29 fps |
| 0.08 | 09-10 | Bit-exact layout/direct-read work; Rise of the Ronin XeSS path; bench 24.4 ms, 36–37 fps |
| 0.09 | 09-11 | Upsample projections to f16 raster (bit-exact, −0.2 ms); Magpie build works with any game (about 30 fps) |
| 0.10 | 09-11 | Black-block root cause fixed: clamp to ±448 before E4M3 conversion (`DLSS5_BUILD_C32_SAT_CAST`) |
| 0.11 | 09-11 | Takeover 20–30 s → about 3.5 s (weight prefetch, batched residency, shader disk cache) |
| 0.12 | 09-12 | On-screen notices (wrong resolution / initialising / failed); `DLSS5_NOTICE` |
| 0.13 | 09-12 | `DLSS5_SHOW_FPS`; takeover by declared output state |
| (0.14) | 09-12 | Magpie full package: FPS refresh every 3 s, cleanup |
| 0.15 · [pkg](https://pan.quark.cn/s/1601ca8f80ae) | 09-13 | Windows ≤1920×1080 fitted by aspect (`DLSS5_FIT_INPUT=1`); also [0.15-900P](https://pan.quark.cn/s/a5339e4c8549) |
| 0.20 · [pkg](https://pan.quark.cn/s/3c8b5329353c) | 09-17 | **HIP backend**: COMGR-built gfx1201 kernels, bit-exact with the DX12 chain; 900p about 15.5 ms, in-game 900p 52 fps |
| 0.21 · [pkg](https://pan.quark.cn/s/85a507a744bd) | 09-17 | `DLSS5_NETWORK_HEIGHT=auto` tier selection; bit-exact with 0.20 |
| 0.22 · [pkg](https://pan.quark.cn/s/03f9995d0551) | 09-17 | 900 tier padding 1024→960 rows (−0.9 ms); **output changed** (about 31.5 dB vs 0.21), `900w` restores the old layout |
| 0.23 · [Magpie](https://pan.quark.cn/s/548e52cc4f49) · [OptiScaler](https://pan.quark.cn/s/8b5a402012a2) | 09-18 | HIP device chosen by adapter name on multi-GPU/iGPU machines; bit-exact with 0.22 |

## 0.24 (09-19)

Download: [OptiScaler](https://pan.quark.cn/s/1f32ffbd2e96) (HIP)

- **Changed**: pre-upscale route — the game's low-resolution colour → DLSS5 → OptiScaler's FSR 3.x/4 → final output, asynchronous on the same queue. Only this project's add-on changed; OptiScaler itself, weights and kernels unchanged.
- **Effect**: Stellar Blade 2560×1440, FSR Quality (input 1707×961) about 34–35 fps.
- **Behaviour**: DLSS5 history reset every frame for now (FSR temporal kept); network input still must be ≤1920×1080.
- **Bit-exact**: network output same as 0.23.

## 0.24.1 (09-19)

Download: [OptiScaler](https://pan.quark.cn/s/4f73a54d0ff9) (HIP)

- **Changed**: config/asset lookup — when the DLL is loaded from a subfolder such as `_storage_` with no `DLSS5-AMD` next to it, also look next to the game EXE (avoids reading stale development configs).
- **Bit-exact**: kernels and weights unchanged.
- Does not address the RE9 same-command-list pre-upscale limitation.

## 0.24.2 (09-19)

Download: [OptiScaler](https://pan.quark.cn/s/f74aaa5c7f9a) (HIP)

- **Changed**: the add-on no longer reads config and locks the task table on every draw when there is no pre-upscale task; less log-counter contention; F6-off bypasses pre-upscale capture and colour copy. Repacked the same day to add the FPS/status display switch.
- **Effect**: Stellar Blade hub about 49 fps (was about 31, CPU overhead).
- **Bit-exact**: kernels and weights unchanged.

## 0.25 (09-19)

Download: [Magpie](https://pan.quark.cn/s/09630ed99606) · [OptiScaler](https://pan.quark.cn/s/636691131c5f) (HIP)

- **Changed**: C32/multi-head attention reuse the exponent; simpler reciprocal; intermediate features and decoder output passed as FP8 bytes; full decoder groups take a fast path. Fixed a missed tail write on the 900 tier and loading from CJK paths. **New gfx1200 (9060/XT) kernels**, selected automatically alongside gfx1201.
- **Effect**: Magpie 1080p DLSS5-only about 37 fps, roughly unchanged.

## 0.26 (09-19)

Download: [Magpie](https://pan.quark.cn/s/7ce2ca11db43) · [OptiScaler](https://pan.quark.cn/s/c880a70f0824) (HIP)

- **Changed**: FFN reads FP8 byte fragments directly (no shared-buffer staging, two fewer syncs); C256 weights pre-arranged into contiguous matrix fragments at init. Added the missing R11G11B10 decode shader (fixes Lies of P black screen at low effects quality); shader compile/bind checks.
- **Checks**: package files and all 44 shader variants verified.

## 0.26.1 (09-20)

Download: [OptiScaler-REFramework](https://pan.quark.cn/s/624c87a6aa11) (HIP, RE9 only)

- **Changed**: post-upscale HIP route for RE9-style integrations — R10G10B10A2/FP16 conversion, FSR post-processing, fixed 900P compute, 1080P SDR output guard; status/resolution/Present FPS and F7 info toggle. Bundles REFramework, OptiScaler, ReShade, full model and both architectures' kernels, with the 0.26 optimisations.
- Only tested on Resident Evil 9; use the general packages for other games.

## 0.27 (09-20)

Download: [Magpie](https://pan.quark.cn/s/ec3a3282aa76) · [OptiScaler](https://pan.quark.cn/s/004278159ed8) · [OptiScaler-REFramework](https://pan.quark.cn/s/010683548f68) (HIP)

- **Changed**: exact streaming ViT attention (less intermediate storage and re-reading, same math and rounding). Optional R3 adaptive reuse (change detection, longer cache when static, fused submit), **off by default**.
- **Bit-exact**: streaming ViT matches; adaptive reuse is an optional lossy switch.
- 44 shader variants per package and per-file ZIP checks passed; no INT4/pruning.

## 0.28 (09-22)

Download: [Magpie](https://pan.quark.cn/s/11547f398eb4) · [OptiScaler](https://pan.quark.cn/s/f7f423b0ea3a) (HIP)

- **Changed**: six lossless kernel optimisations — shared RGB reads, C128/C256 zero-padding skip, fixed-size ViT expand/projection and decoder projection.
- **Effect**: Stellar Blade image/fps roughly unchanged.
- The RE9 0.28 download was withdrawn in favour of 0.28.1.

## 0.28.1 (09-22)

Download: [OptiScaler-REFramework](https://pan.quark.cn/s/1375693a0d21) (HIP, RE9 only)

- **Changed**: oversized real inputs rejected before HIP init while keeping the original upscaler; failed init rolls back safely and recovers when the size is valid again; in-flight frames protected. Host and runtime must be updated together; source and TheAutomatic's credit ship with the package.
- **Checks**: 10-group / 12-submitted-frame regression and first user play passed.

## 0.29 (09-23)

Download: [Magpie](https://pan.quark.cn/s/fe1b6af36cad) · [OptiScaler](https://pan.quark.cn/s/209e04e7acaf) · [OptiScaler-REFramework](https://pan.quark.cn/s/505d38a63a85) (HIP) · [Google Drive mirror](https://drive.google.com/drive/folders/1VPsX33sLTxBG4J8kJ_IzBDlkbBTCc5Eo?usp=sharing)

- **Changed**:
  - Inputs above 1920×1080 are no longer rejected: scaled into the 1080 tier, then restored to the original resolution the way the original codec does (`DLSS5_FIT_LARGE=1`, issue #6).
  - Six bit-exact kernel optimisations since 0.28: fence scope, folded C32 FFN, byte chain + vectorised input, register-resident attention, in16 aliasing, transposed FFN tail.
- **Effect**: kernels about −7%; Stellar Blade 900P about 60 fps, 2K Native AA 44 fps; RE9 Native AA works (ultrawide not tested).
- **New switch**: `DLSS5_FIT_LARGE=1` (on in templates).
- RE9: host unchanged, runtime updated.

## 0.30 (09-25)

Download: [Quark](https://pan.quark.cn/s/80a735ab9f88) · [Google Drive mirror](https://drive.google.com/drive/folders/1pKZpLosgJXxUOZTMg_m0sbCipX9Q3WYo?usp=sharing) (three packages)

- **Changed**:
  - Any-order chain launches with per-tile flags (home-made programmatic dependent launch, `DLSS5_HIP_PDL=1`) on the C64–C256 chain.
  - Full-row FFN stores.
  - Cyberpunk 2077 zero-config: regular `OptiScaler.ini` has `[Inputs] EnableFfxInputs=false`; `DLSS5_PRE_UPSCALE_ASYNC=auto` (2077 synchronous: transient aliased colour buffer); `DLSS5_STRENGTH=auto` (2077 transfers luma only).
  - Fixed neural processing disappearing after tier/resolution changes (pinned FSR context).
- **Effect**: PDL 900P about −1.6%, 1080P −0.6%; full-row FFN −0.6%. Stellar Blade 900P→2K 60–61, 1080P→2K 47–48; 2077 low Balanced 51–52, Quality 41.
- **New switches**: `DLSS5_HIP_PDL=1`, `DLSS5_PRE_UPSCALE_ASYNC=auto`, `DLSS5_STRENGTH=auto` (template defaults).
- **Bit-exact**: PDL and full-row FFN are bit-exact.
- **Folder**: `results/pdl-chain-20260925`.
- RE9 package: same kernels, host/runtime as 0.29.

## 0.31 (09-26)

Download: [Quark](https://pan.quark.cn/s/e76b8611e3cc) · [Google Drive mirror](https://drive.google.com/drive/folders/1xtBe_XhgF9eqBlrlIQMgWcEkzm0UKHIZ?usp=sharing) (three packages)

- **Changed**:
  - Tier selection: an input within 110% of a tier on both axes is scaled down into it (2K Quality 1707×961 → 900 tier; previously upscaled into 1080).
  - Wave-owned kernels (whole C32/C64/C128 blocks + C256 attention, `DLSS5_HIP_WAVE_OWNED=1`).
  - C512 QKV/mix at 32 tokens (`DLSS5_HIP_C512_M32=1`).
  - ViT projection 64 columns (`DLSS5_HIP_VIT_PROJ_N64=1`).
  - Regular package defaults `DLSS5_VIT_ADAPTIVE=1` (adaptive reuse: +3 fps when static, off automatically in motion).
  - Five new modules (c32-wave1, c64-wave2, c512-m32-mh, c512-m32-deep, vit-wide-deep); 29 modules per architecture.
- **Effect**: wave-owned about −6% network; C512 M32 about −1.3%; ViT N64 about −1.8% at 1080. Stellar Blade main menu 2K Quality 57, 2K Native AA 43–44.
- **Bit-exact**: the three kernel changes are bit-exact; tier selection changes which tier 2K Quality uses (behaviour change); VIT_ADAPTIVE is lossy reuse (can be turned off).
- **Folders**: `results/c64-wave2-20260926`, `wave-owned-*`, `c512-ffn-20260926`, `m32-sweep-20260926`.
- RE9 package: host/runtime as 0.30; new kernels shipped but not enabled.

## 0.32 (09-26)

Download: [Quark](https://pan.quark.cn/s/b805e071405c) · [Gofile mirror](https://gofile.io/d/CZ67LYIc) (three packages)

- **Changed**:
  - VRAM pool: the driver never returns D3D12 shared buffers imported by HIP, so they are now reused per tier (40 switches: +3 GB → flat).
  - C32 wide reads (vector input loads).
  - RE9 runtime reads flags (`DLSS5_HIP_*` / `SKIP_BLOCKS` / `FIT_LARGE` / `NETWORK_HEIGHT`), enables the 0.31 kernels by default, stays compatible with the old two-argument `EnqueueHip`; PR #9 merged.
- **Effect**: C32 wide reads −0.8% / −0.9%; offline 900 tier 10.74 ms, 1080 tier 15.01 ms; RE9 medium 2K Quality 54, native AA 38.
- **Bit-exact**: C32 wide reads are bit-exact.
- **Folders**: `results/vram-leak-20260926`, `c32-wave-phase-20260926`, `re9-runtime-flags-20260926`.

## 0.33 (09-27)

Download: [Quark](https://pan.quark.cn/s/6bb64e46ab67) · [Gofile mirror](https://gofile.io/d/8yAjJX1b) (three packages)

- **Changed**:
  - FP8 packing: `CW_PACK8` in c32-wave1, `W2_PACK8` in c64-wave2 — one `cvt_pk` converts two values into a fragment word.
  - Add-on: AE/EXACT on the pre-upscale status line; F7 toggles on-screen text; shared environment-option parser.
- **Effect**: offline 900 tier 10.74→9.80 ms, 1080 tier 15.01→13.64 ms (about −9%). Stellar Blade 1080p native AA EXACT main menu 49–50, common scenes 53–54.
- **Bit-exact**: yes, against 0.32.
- **Folders**: `results/c64-block-fused-20260927`, `pack8-20260927`.
- RE9: host/runtime as 0.32 (modules only).

## 0.34 (09-27)

Download: [Quark](https://pan.quark.cn/s/4b572b0a5b81) · [Gofile mirror](https://gofile.io/d/cfHqVzD1) (three packages)

- **Changed**:
  - fmed3 clamps (`HIP_FMED3_CLAMP`, C32 `HIP_FP8_SAT_MODE 3`) and `W2_PACK8 6` (segmented FP16_OVFL + fma(x,y,+0) packing); the full module set is built from the production recipe by `hip/build-modules.ps1` (3 fallback modules rebuilt from source).
  - PDL counter rollover guard; PDL buffers freed on teardown.
  - RE9 host aa3761f2: follows the queue that actually executes the split list + 8-evaluation watchdog (Onimusha); runtime ca6d6bdc: resize leak 35 MB→0, geometry logged on every size/tier change; host/runtime source archive regenerated.
- **Effect**: Stellar Blade 1080p AA EXACT main menu 50–51 / scenes 54; RE9 medium 2K Quality 58, native AA 41; Onimusha 2K Quality about 60.
- **Bit-exact**: yes, against 0.33.
- **Folders**: `results/fmed3-ovfl-20260927`, `ovfl-census-20260927`, `c64-hand-asm-20260927`, `pdl-audit-20260927`, `onimusha-presr-20260927`, `re9-runtime-leak-20260927`.

## 0.35 (09-27)

Download: [Quark](https://pan.quark.cn/s/83e6172e6c79) · [Gofile mirror](https://gofile.io/d/NnF4GitT) (three packages)

- **Changed**:
  - Three C32 rounds: duplicate FP8 round trips removed (`CW_DIRECT_OUT`, `CW_PREFIX_DIRECT_OUT`), vectorised RTZ/LDS stores (`CW_RTZ_PAIR`), per-segment saturation mode (`CW_PACK_MODE_MASK`), full-window fast paths in prefix/finish (`CW_PREFIX_FULL_TILE` etc.).
  - ViT byte stream (`DLSS5_HIP_VIT_STREAM=3`, new `vit-stream` module: attention output goes to the projection as bytes; works with adaptive reuse).
  - Add-on 4151123e; 30 modules per architecture; RE9 runtime 432d8ccf (same switch; host aa3761f2 unchanged).
- **Effect**: offline 900 tier about 9.3 ms, 1080 tier about 12.75 ms. Stellar Blade 1080p AA EXACT about 56.7 (0.34: 54); RE9 medium 2K Quality 58–59, native AA 42.
- **New switch**: `DLSS5_HIP_VIT_STREAM=3` (template default).
- **Bit-exact**: all changes bit-exact against 0.34.
- **Folders**: `results/c32-aco-20260927`, `c32-round2-20260927`, `c32-round3-20260927`, `vit-bytestream-20260927`.

## 0.36 (09-28)

Download: [Quark](https://pan.quark.cn/s/e5afdaca0769) · [Gofile mirror](https://gofile.io/d/Z1hWdjcB) (all three packages)

- **Summary**: add-on d2290ad7; 30 modules per architecture; RE9 runtime 7ce2bc21 (host aa3761f2 unchanged); input shader `native_game_rgb_input.hlsl` 5be59a41 (matches the direct input write).
- **Cumulative effect (vs the 0.35 release packages, two ABBA rounds in one batch)**: offline 900 tier 9.37 → 8.58 ms (−0.79 ms, −8.5%), 1080 tier 12.71 → 11.58 ms (−1.13 to −1.14 ms, −8.9%). Kernel launches per frame at 1080: 214 → 182.
- **Bit-exactness**: **0.36 is not bit-identical to 0.35** — the float FMA activation (item 4 below) is a deliberate numeric change with essentially unchanged error against NVIDIA's reference; 0.36 is the new bit-exact baseline. Every other item was bit-exact against the build before it.
- **New switches**: `DLSS5_DIRECT_IO` (1 in the regular/Magpie templates, not set for RE9), `DLSS5_FRAME_STATS=<seconds>` (0 in templates).
- **What changed** (in order):

1. **C64–C256 deep pass** (c64-wave2 recipe: whole-group byte input reads, RTZ pairing, direct coordinates): offline 900 −0.7%, 1080 −0.8%; bit-exact; modules only. `results/mh-round1-20260927`, `tier900-20260927`. Stellar Blade 1080p AA EXACT 57.1.
2. **Frame-time distribution log** `DLSS5_FRAME_STATS=<seconds>` (add-on + RE9 runtime, writes `DLSS5-AMD\logs\frame-stats.txt`, 0 in templates). `results/frame-stats-20260928`.
3. **Two cuts from a line-by-line ACO comparison**: removed a redundant NaN canonicalisation before the C32 activation; bounded reciprocal in C64–C256 softmax (sum order and error correction kept). 900 −0.82% / −0.65%, 1080 −0.75% / −0.74%; bit-exact. `results/aco-lineup-20260928`.
4. **float FMA activations (a deliberate numeric change; the bit-exact baseline changes on 09-28)**: the multiply-add in the C32, C64–C256 and ViT/C512 activations is contracted to a float FMA (previously two roundings, kept to match HLSL `precise`; the original NVIDIA code uses half FMA). 900 saves 0.110–0.115 ms, 1080 0.148–0.151 ms (about 1.2%); error against the original NVIDIA output essentially unchanged (single-frame RMSE 0.008038→0.008037). This output is the bit-exact baseline from now on. `results/fma-vs-nvidia-20260928`, `float-fma-20260928`.
5. **Direct input / direct output** `DLSS5_DIRECT_IO` (0 old path, 1 input written straight into the HIP shared buffer, 3 also lets FSR read the decode output directly): one 35 MB copy and one copy-back removed; offline −0.02 to −0.05 ms; network output bit-exact. Temporal sessions (Magpie), `DLSS5_OVERLAP` and non-RGBA16F formats fall back automatically; RE9 not affected. `results/zero-copy-io-20260928`.
6. **C256 whole-block fusion** (several token groups share one weight read; FFN weight reads halved; main kernel VGPR 190→154): 1080 −1.67% / −1.63% (about −0.20 ms), 900 keeps the old path; dispatches per frame at 1080 214→198; bit-exact. `results/c256-fusion-20260928`.
7. **C512 fusion + C64/C128 weight sharing**: one dispatch fewer per C512 block (1080 198→185, 900 214→201); C64/C128 weight reads halved. 900 −3.59% (about −0.33 ms), 1080 −2.55% / −2.63% (about −0.31 ms); bit-exact. Offline 1080 tier about 11.82 ms, 900 tier about 8.72 ms. `results/c512-fusion-20260928`.
8. **Upsample fused into the first block**: the C64/C128 and C32 upsamples merged into the next level's first block, 3 fewer launches per frame (1080 185→182, 900 201→198); 900 −0.17 to −0.18 ms, 1080 −0.25 to −0.26 ms; bit-exact. ViT and downsample candidates measured no gain and were not merged. `results/fusion-round3-20260928` (with `package-036-checklist.md`).

In game (local, RX 9070 XT, EXACT, standing still): Stellar Blade 1080p native AA about 57 → 60 (at the 60 Hz windowed-mode cap); 2560×1440 native AA 52–53 after the C512 fusion, 54 final (the in-game comparison setting from now on).


## 0.37 (09-29)

Download (all three packages): [Quark](https://pan.quark.cn/s/7dbfdc6425fd) · [Gofile mirror](https://gofile.io/d/onqeAHST)

- **Summary**: add-on b77bbc3c; 31 modules per architecture (new `swin-persistent.hsaco`); RE9 runtime 2c103f6e (host aa3761f2 unchanged); shaders identical to 0.36 (input shader 5be59a41).
- **Bit-exact**: **fully bit-identical to 0.36** (09-28 float-FMA baseline; 7 cases, 168 EXACT/AE frames plus rollover/timeout stress frames, checked at every step). Nothing lossy.
- **Cumulative**: network offline 900 tier about 8.5 → 8.0 ms; launches per frame 900 tier 198 → 179, 1080 tier 182 → 162. Stellar Blade 2560×1440 native AA, EXACT 54 → 55–56 (local).
- **New switch**: `DLSS5_HIP_SWIN_RUN` (C256 persistent stage; source default 0, **set to 1 in all three release templates**; the RE9 runtime reads it too; 0 restores the previous launches).
- **Package extras**: the regular OptiScaler package now also ships `ReShade.ini` (`TutorialProgress=4`, no Home-key tutorial overlay), like Magpie; the RE9 source archive now includes the HIP recipes' `.inc` files.
- **Changes** (in order, each bit-identical to the step before):

1. **C512 compact point-wise layout**: FFN/conv run on the effective tiles only (1080 tier 160 → 135 4×4 tiles); shifting and padding moved to the attention read; windows and softmax unchanged. 900 −0.16 to −0.18 ms, 1080 −0.23 to −0.25 ms (about −2% each); 1080 launches 182 → 169. `results/deep-layers-20260929`.
2. **Kernel-map cuts**: after a full per-kernel 1080 comparison (our 169 vs reference 154 launches), C512 head pooling + projection fused into one launch (head group fusion) and the ViT attention score layout transposed. 900 −0.02 to −0.04 ms, 1080 −0.12 to −0.14 ms (1.0–1.2%); launches 198 → 197 / 169 → 168. `results/kernel-map-20260929`.
3. **C256 persistent stage** (`DLSS5_HIP_SWIN_RUN=1`): the six inner layers of each C256 encoder/decoder stage run from a device ready queue; a ~100 ms timeout replays the stage serially on the GPU and disables persistence for the instance, so no bad intermediate leaves the network. 900 −1.90 to −1.94% (about −0.16 ms), 1080 −0.57 to −0.61%; launches 197 → 179 / 168 → 162. `results/swin-persistent-20260929`.
4. **New ViT attention kernel**: exact hardware widening for bounded normal halves, probabilities encoded in register pairs, denominator/AV output transposed. 640-token kernel about 71 → 38 µs; network 900 −2.20 to −2.28% (about −0.19 ms), 1080 −1.50 to −1.58% (about −0.17 ms). `results/vit-attention-20260929`.
5. **ViT QKV, five waves sharing weights** (W5): five waves share one weight copy through LDS (8 KB double-buffered blocks), reads divided by about 5 without reducing waves; 640-token kernel 48.8 → 37.0 µs. Network 900 −0.42 to −1.39%, 1080 −0.74 to −1.07%. The new host detects the export and falls back with older modules. `results/vit-qkv-20260929`.

Not shipped (negative results): C128/C64 persistence (below the 0.5% bar, `results/swin-persistent-c128-c64-20260929`), C512 projection weight sharing (bit-exact but slower, `results/c512-proj-share-20260929`), the `MAKE_RESIDENT` spike (not reproduced offline, `results/resident-spike-20260929`). Package checklist `Development/results/package-037/checklist.md`.

## 0.38 (09-30)

Download (all three packages): [Quark](https://pan.quark.cn/s/6856d875bbe9) · [Gofile mirror](https://gofile.io/d/lzsqfUiE)

- **Bit-exact**: **with default settings fully bit-identical to 0.37** (09-28 float-FMA baseline; 7 cases, 168 EXACT/AE frames plus ticket rollover, checked at every step; the add-on and RE9 runtime shipped were rebuilt from the release source and re-checked against the installed build on the same 168 frames + rollover, all identical). The only lossy item is the opt-in `DLSS5_NETWORK_1080_ROWS=1088`, off by default.
- **Effect** (offline full-network replay, NativeGameFrame, 1000 frames minus the first 200, ms per frame): 900 tier about **8.0 → 7.6 ms**, 1080 tier about **10.8 → 10.4 ms** (release modules measured 900 7.551/7.606, 1080 10.413/10.458, two runs, `results/hip-roofline-20260930` section 1; per-kernel map `results/kernel-map-v3-20260930`). Launches per frame: 900 tier 179 → 162, 1080 tier 162 → 158. In-game runs (Stellar Blade, Onimusha) are correctness checks only (no flicker, artefacts or crashes); frame-rate readings are not used as evidence.
- **New switches**:
  - `DLSS5_FORMAT_FALLBACK` (1 in all three templates, source default 1): colour formats that used to be rejected — R9G9B9E5, B8G8R8X8, R10G10B10A2, R32G32B32(A32), R16G16B16A16/R8G8B8A8 SNORM, B5G6R5, B5G5R5A1, B4G4R4A4 — are converted to RGBA16F by one compute pass on the regular package's pre-upscale route (new `native_format_convert.hlsl`) and then take the normal route; the RE9 runtime uses its private FP16 output route. Formats accepted before never reach the table (bit-exact). Rejected formats are logged by name. Post-upscale / Magpie / XeSS routes unchanged. 0 = original table. `results/product-fmt-reload-20260930`.
  - `DLSS5_HOT_RELOAD` (1 in the regular/Magpie templates, source default 1; not applicable to RE9): editing `DLSS5_STRENGTH` / `DLSS5_NOTICE` / `DLSS5_SHOW_FPS` in the flags file while the game runs applies within a second; other keys still need a restart. No edit, no change.
  - `DLSS5_NETWORK_1080_ROWS` (templates 1152 = NVIDIA geometry): **opt-in `1088`, LOSSY, off by default** — the 1080 tier computes 1088 rows, network about −0.47 ms (4.4%), about 56 dB vs 1152 over the frame, bottom 32 rows slightly worse. `results/geom-1088-20260930`.
  - Internal host switches (default 1, normally untouched): `HIP_C512_PAD16`, `HIP_C256_FFN_W16`; they fall back to the old path with older modules or too-small buffers.
- **Changes** (in order, each bit-identical to the step before; figures are each step's own ABBA):

1. **900 tier: C512 shift_pack removed**: producers allocate 16-token-padded buffers (1500 → 1504), C512 blocks read in place, 13 `mh_shift_pack` launches gone; host only. 900 −0.09 to −0.11 ms, 1080 unchanged. `results/shift-pack-900-20260930`.
2. **C32 block-4 skip/downsample stored as E4M3 bytes**: their values are exact E4M3 already; traffic drops to a quarter. 900 −0.05 ms (0.62%), 1080 −0.09 ms (0.82%). `results/c32-align-20260930`.
3. **C32 diagonal residual skips all-zero halves** (`CW_DIAG_ONLY`): 1080 about −0.04 ms. `results/small-cuts-20260930`.
4. **I+P+O**: C32 input/prefix without the half round trip; occupancy caps for C512 mix and ViT contract. 900 −0.03 ms, 1080 −0.02 to −0.03 ms. `results/small-wins-retest-20260930`.
5. **Composite quantisation**: `FP8(Hrtz(x))` at WMMA byte exits becomes an integer bit mask, dropping the f32→f16→f32 round trip; proved over all 2³² inputs. c64-wave2/swin-persistent (`results/composite-quant-20260930`) and two C512 exits (`results/composite-quant-c512-20260930`), −0.005 to −0.03 ms each.
6. **C256 FFN weights in 16-byte fragments**: one 16-byte load feeds two WMMAs, k order unchanged; falls back with older modules/hosts. 900 −0.01 to −0.03 ms. `results/c256-w16-20260930`.
7. **C32 prefix down / block-69 main stored as E4M3 bytes**: 900 −0.01 to −0.02 ms, 1080 about −0.02 ms. `results/prefix-post-20260930`.
8. **Three wide-store rewrites**: C32 prefix byte tail (900 −0.04, 1080 −0.07 ms, `results/prefix-post-arith-20260930`), C32 finish byte tails (900 −0.04, 1080 −0.05 ms, `results/tail-vec-20260930`), C512 t8 byte copies via LDS transpose (about −0.01 to −0.03 ms, `results/deep-tail-20260930`).
9. **C512 QKV-attention: redundant F dropped + bounded reciprocal**: the extra clamps at the AV/QKV exits removed, softmax division replaced by rcp + two Newton steps; both tiers, three rounds −0.02 to −0.03 ms. `results/c512-av-f-20260930`.
10. **F/division clean-up across the network**: only deep_fast-packed taken (900 −0.01 to −0.04, 1080 −0.01 to −0.03 ms). `results/f-sweep-20260930`.

- **Package**: new `native_format_convert.hlsl`; the three flags templates carry the three switches above; add-on and RE9 runtime rebuilt from the release source (tag 0.38); RE9 host unchanged; RE9 source archive regenerated.
- Not shipped (bit-exact but not faster everywhere, macros default 0): D3D→HIP GPU polling `DLSS5_HIP_INPUT_POLL` (`results/handoff-gpu-20260930`), C512 V transpose (`results/c512-compact-vt-20260930`), W16 for C64/C128 (`results/w16-c64-c128-20260930`), C512 FFN LDS weight sharing (`results/c512-ffn-lds-20260930`), Infinity Cache hot reuse (`results/infinity-cache-20260930`). Package checklist `Development/results/package-038/checklist.md`.

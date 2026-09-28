# Deep layers 2026-09-29 reproduction

Task base: `50dc5cd5`, production baseline 0.36. Result: `../../../results/deep-layers-20260929/README.md` (from this directory the repository result path is `Development/results/deep-layers-20260929`). Work directory on 9070: `D:\DLSSNR-Lab\hip-backend\deep-layers`.

## Frozen baseline

`snapshot.ps1` captured the **pre-install** Stellar add-on d2290ad7, all 60 modules and flags. `flat-A`, `baseline-gfx1200`, `before.json`, `base-flags.txt`, `benchmark-base.exe` are retained there. Do not rerun snapshot on the newly installed game and call that 0.36. The runner was copied from `fusion-round3/benchmark-production.exe`. Input: `hip-backend/live-menu-before.f16`; assets: `zero-copy-io-20260928/assets`.

## Candidates

`bash build-hosts.sh /tmp/deep-repro` recreates isolated source and hosts from the task commit. R/RF share one module and differ only in the host selector. Copy each runner's `hip` tree to remote `hip-R`, `hip-V`, `hip-C`; `build.ps1` compiles candidates. New macros default 0.

|Set|Build macro / host macro|Outcome|
|---|---|---|
|R|C512_REGISTER_FFN=1 / C512_REGISTER_MODE=1|Single-wave register FFN, slower|
|RF|same module / C512_REGISTER_MODE=2|Also fuses mix, slower|
|V|VIT_EXPAND_CONSUMER_FLOAT=1 / VIT_EXPAND_CONSUMER_FLOAT_HOST=1|Consumer float pack, slower|
|C|C512_COMPACT_QKV_ATTN=1 / C512_COMPACT_HOST=1|Compact pointwise prototype, accepted|
|P|current production recipe / current host|Same C arithmetic and 91 kernel bodies; source concatenation order differs|

`C-attention.inc` records the exact candidate source; production lives in `hip/c512_qkv_attention_compact.inc`. Production needs the new host **and** c512-m32-mh module; no new user flags. Compatibility conditions retain the old route for other diagnostic configurations. `build-production.ps1` compiles both architectures and macro-off controls. The controls match old .text/.rodata/.note. gfx1200 is compile-only; all GPU measurements use gfx1201.

## Replay

`regression.ps1` supports `-Set C -CandidateBenchName benchmark-C.exe`, or `-Set P -CandidateBenchName benchmark-production.exe`. `-CorrectnessOnly -Batch exact`, then `-Adaptive 1 -Batch adaptive` runs seven 12-frame cases. `validate.ps1` does both for P. `-TimingOnly -Batch abba2` runs 900/1080 ABBA, 1000 frames per slot, discard 200. Short screens use `-TimingFrames 200` and discard 32. Game-flags validation uses `-GameFlags -Batch gameflags -Only 1080-motion -CorrectnessOnly` and is accounted separately.

All GPU scripts check for games/benchmarks before work. Do not overlap a microbench, game or compilation with timing. DIRECT_IO=3, BENCH_PLAIN=1, graph off, PDL=1; exact timing. Correctness uses fixed CODEC_SRGB=1 fixture; game-flags check uses current CODEC_SRGB=0. Offline replay tests input direct IO, not the game's FSR output handoff.

`collect.ps1`, `collect-adaptive.ps1`, `export-small.ps1` produce timing/hash/AE and raw CSV evidence. `analyze-results.py <result-directory>` checks per-frame hashes against the 09-28 float FMA goldens and AE decisions against baseline, and computes ABBA means. `trace.ps1` uses a diagnostic-only host printing TOPO at the final Run launch decision; production contains no trace output. `runtime-check.ps1` checks a separately built shared runtime against 0.36 without installing RE9.

## Other investigations and install

`daniel/` contains the independently launchable synthetic FFWD benchmark, ABI and build instructions. `fp8/` contains the complete 16-weight census and the **historical** FP16→FP8 WMMA counterexample; RF8 was not built this round.

`install.ps1` validates the frozen baseline, checks games, verifies payload hashes, backs up, installs addon + two modules, and updates the installed SHA256SUMS. On failure it restores. Rollback: run it with `-RestoreBackup D:\DLSSNR-Lab\hip-backend\deep-layers\backups\stellar-20260929-010247`. `verify-installed.ps1` compares all 60 game modules against the repository manifest. Installation preserves DIRECT_IO=3 and MAKE_RESIDENT_EVERY=60; no package published.

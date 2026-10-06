# config-layers-20261003: three config files (default -> custom -> native) + environment

Shared reader `src/native_config_layers.h` (rules in its header comment and `scripts/CONFIGURATION.md`). Readers switched to it:
add-on environment loader (`native_game_oneshot.h`), hot reload (`native_hot_flags.h`: stamp over all three files), every direct
key read (`native_submission_order_probe.cpp` x10: FIT_INPUT, FIT_LARGE, NOTICE x2, SNAPSHOT_FRAME x2, SPLIT_SUBMIT, UPSCALER,
PRE_UPSCALE_DEBUG, RESERVE_VRAM_MB; `native_pre_upscale.h` x4: PRE_UPSCALE, FREE_RES, FIT_LARGE, NOTICE/SHOW_FPS/FRAME_STATS,
PRE_UPSCALE_ASYNC; `native_format_fallback.h`), lab-root detection (`native_lab_paths.h`), RE9 runtime (`LmxxfNrRuntime.cpp`
LoadFlagsFileOnce, whitelist + `DLSS5_FRAME_STATS`). Magpie = the same add-on binary.

## Tests
- `tools/test_config_layers.cpp`: 28/28 on Linux (g++) and on the 9070 (mingw build `tcl.exe`): only default, custom > default,
  native > custom, env > all, env-only key, missing layers (custom / default / all), old native-only install, duplicate key (last wins),
  empty value overrides (and native non-empty over custom empty), BOM, comments, leading space, trailing spaces, no final newline, 600-byte value.
- 19 groups (full.ps1 correctness, AE + rollover, base = main d349cc92 bench 39BBF6A9, candidate = branch bench E95AF445): 19 SAME.
  The first attempt was aborted by the watchdog (a game started at 10:38); the guard waited and reran.
- RE9 replay (rt_bench 1707x961, 12 frames, each side twice, rerun SAME; old = installed runtime E200E8A6, new = A156339E):
  | side | 900 | 1080 |
  |---|---|---|
  | old, no file | 6f961945261a355c | aaa31e2dffa3a1b5 |
  | new, no file | 6f961945261a355c SAME | aaa31e2dffa3a1b5 SAME |
  | old + installed Onimusha native-game-flags.txt | ab6b7731d2fa6da9 | 45d9905fea25c5ad |
  | new + default-config (hip-re9 template) + same native | ab6b7731d2fa6da9 SAME | 45d9905fea25c5ad SAME |
  | new + default + custom MULTI_PASS=2 | 22464e530cded51b (differs: custom applied) | f51c14f87d1b271a |
  | new + default + custom MULTI_PASS=2 + native (has MULTI_PASS=1) | ab6b7731… = native wins | 45d9905f… |
  | new + default + custom MULTI_PASS=1, env MULTI_PASS=2 | 22464e530cded51b = custom-2 side (env wins) | f51c14f87d1b271a |
  The run log printed BAD for "newC2 = mp2env" and "newC1E2 = mp2env": wrong expectation (mp2env has no template file, so its other
  settings differ); the right comparison is newC1E2 = newC2, which holds. rt9.ps1 is corrected. runtime-smoke exit 0, errors=0.
  Flags line: `layers=D-N applied=19 env_kept=4` (old native-only: applied=15; +STYLE/1080_ROWS/FREE_RES from default, +FRAME_STATS whitelist).

## Install (9070)
Stellar add-on E50D6E4A -> 3C71B955; Onimusha runtime (+ _storage_) E200E8A6 -> A156339E. Both DLSS5-AMD folders got default-config.txt
(templates 9677BDB5 / 028149BE) and custom-config.txt (comment-only, 53CCDB34); native-game-flags.txt untouched (AC8CFE14 / 415454E3).
Backup `D:\DLSSNR-Lab\config-layers-backups\20261003-105814`; restore:
`powershell -File D:\DLSSNR-Lab\deployments-config-layers-20261003\install.ps1 -RestoreBackup 20261003-105814`.
Scripts: `Development/HIP/experiments/config-layers/`, install `Development/deployments/config-layers-20261003/`.

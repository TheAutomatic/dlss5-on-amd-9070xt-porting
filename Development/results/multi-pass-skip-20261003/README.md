# multi-pass-skip-20261003: DLSS5_MULTI_PASS_SKIP_BLOCKS + multi-pass hotkey / hot reload

## A. DLSS5_MULTI_PASS_SKIP_BLOCKS (lossy, passes 2..N only)
Where: `Development/HIP/hip_reference_network.h` (`MultiPassSkipFromEnvironment`, `MultiPassRest` adds the list to the configured skip set
for passes 2..N and restores it afterwards). Pass 1 is untouched. Unparsable list -> empty + stderr; a block the pipeline cannot skip
(C64/C128/C256 5-22/48-65 with the MH byte stream, C32 without the raw chain) -> empty + stderr. RE9 whitelist has the key.

Harness: offline bench, installed Stellar gfx1201 modules (SUMS F3EFDC16); hosts base = main (E95AF445), M = branch (FFAF61BA).
The harness flags file is the old release recipe (skip 42,43,46, bit-exact); every row below adds the **current default**
(`DLSS5_SKIP_BLOCKS=` = all 71 blocks, `DLSS5_FAST_NUMERIC=1`). Timing: 1000 frames, frames >= 200, 2 ABBA rounds each
(the base side of every round = base host, old recipe, one pass: 7.27-7.41 / 10.06-10.11 ms, a little higher than the morning's 7.05/9.82).

| set (`DLSS5_MULTI_PASS=3` + skip list) | 900 avg ms | 1080 avg ms | PSNR vs 3 passes all blocks (7 cases, mean / worst frame) |
|---|---|---|---|
| 1 pass, current default (reference) | 7.42 / 7.52 | 10.30 / 10.32 | - |
| empty (3 passes, all blocks) | 21.06 / 21.22 | 29.81 / 29.81 | reference |
| `42,43,46` | 20.68 / 20.81 (-0.4) | 29.30 / 29.31 (-0.5) | 43.9-46.0 / 43.2-46.0 dB |
| `31-38,40-47` (ViT + C512 up) | 18.39 / 18.54 (-2.7, -13%) | 25.68 / 25.70 (-4.1, -14%) | 34.1-35.0 / 33.9-35.0 dB |
| `23-38,40-47` (+ C512 down) | 17.42 / 17.57 (-3.6, -17%) | 24.28 / 24.31 (-5.5, -18%) | 33.2-33.6 / 32.9-33.6 dB |

PSNR is against **our own** 3-pass all-block output (8-bit PPM, peak 255), not against NVIDIA. For scale: 3 passes vs 1 pass is
35.0 dB here, and the ViT+C512-up set vs 1 pass is 37.5 dB, i.e. skipping those blocks in the later passes takes away a large part of
what the later passes add (lighter, less contrast than full 3 passes); the deep set lands about as far from 1 pass as full 3 passes do,
but somewhere else (33.5 dB from it; dark areas lifted). They are different looks, not a cheaper copy of 3 passes.
Why the saving is small: the skippable blocks are the low-resolution ones (ViT, C512); the cost sits in the full-resolution C32/C64
chain, which the production pipeline cannot skip (byte stream). No earlier per-block quality ablation existed in DevHistory, so the
aggressive sets were picked by family, not by measured single-pass loss.

Checks: full.ps1 19 groups (options unset, hotkey code present, not pressed) **19 SAME**. invalid.ps1 (3 passes, 900, 20 frames):
unset / empty / `abc` / `99` / `10` all give the same hash (363B7977) and the three invalid ones print the stderr line; `42,43,46` differs.
RE9 replay (rt_bench 1707x961, 12 frames, each side twice, rerun SAME; old = installed A156339E, new = 1F7C12CD):
| side | 900 | 1080 |
|---|---|---|
| old / new, no file | 6f961945261a355c SAME | aaa31e2dffa3a1b5 SAME |
| env MULTI_PASS=3 | edc5253053704085 (20.53 ms) | e5791dd4d895d9d0 (29.02 ms) |
| env 3 + SKIP 42,43,46 | 96ee3546cf86e9c0 (20.13 ms) | 51440311a32ff2d9 (28.69 ms) |
| file (native-game-flags) 3 + SKIP 42,43,46 | 96ee3546cf86e9c0 = env | 51440311a32ff2d9 = env |
runtime-smoke exit 0, errors 0.

Screenshots `shots/<case>-<set>.png` (frame 11 of 900-static, 1080-static, 1080-motion; harness preview size): `pass1`, `full`
(3 passes), `skip-42-43-46`, `skip-vit-c512up`, `skip-deep`.

## B. Multi-pass hotkey + hot reload (add-on only)
- Hot reload (`src/native_hot_flags.h`) now also re-reads `DLSS5_MULTI_PASS`; the HIP network applies it before the next network frame
  (`NativeHipNetwork::ApplyHotMultiPass` -> `D3D12Bridge::MultiPass` -> `Network::SetMultiPass`: same value = no call; graph mode is
  rebuilt; feed buffers are allocated on the next multi-pass frame). Logged as `multi_pass=N` in the `event=hot_reload` line and
  `event=multi_pass detail=a->b` in `logs\native-game-oneshot.txt`.
- Hotkey `DLSS5_MULTI_PASS_HOTKEY` (default F9; `F1`..`F24` or a key code; `0` = off), edge-triggered with `GetAsyncKeyState` like the
  F6/F7/F8 keys, polled once per network frame. A press cycles 1->2->3->1 from the count in effect and writes `DLSS5_MULTI_PASS=N`
  into `custom-config.txt` (replace / append / create; BOM and line ends kept; written to a .tmp and renamed). If
  `native-game-flags.txt` also has the key, that line is rewritten too (stderr line). A system environment variable wins: stderr line.
  The hotkey forces the next hot-reload poll (a write in the same file-time tick would not change the stamp). `event=multi_pass_hotkey`
  log line. `DLSS5_HOT_RELOAD=0` = the file is written but nothing applies until restart.
- RE9 runtime: no hot reload, no hotkey (it has no per-frame config poll); only the skip list applies there.
- Tests (`hk.ps1`, `hk_test.cpp`, no key press: calls `CycleMultiPass` then polls): custom missing -> created `DLSS5_MULTI_PASS=2`,
  reload multi_pass=2; CRLF+BOM file -> line replaced, other lines / BOM / CRLF kept; no final newline -> appended; native has the key
  -> both rewritten + stderr; env set -> stderr, reload keeps env value 1; hotkey `0` -> 0, `F10` -> 121, `0x77` -> 119, `Q` -> stderr + F9.
  Bit-exactness with the hotkey present and not pressed: the 19 SAME above (the bench links the same NativeHipNetwork).
  `hkoff.ps1` (base host vs branch host, 900, 20 frames, harness flags): hotkey unset / `0` / `F10` all C3B23A3E SAME (= the base host).
  A real key press in the game is for Zero to try.

Scripts: `Development/HIP/experiments/multi-pass-skip/`. Install: `Development/deployments/multi-pass-skip-20261003/`.

## Install (9070)
Stellar add-on 3C71B955 -> C511E148; Onimusha runtime (+ _storage_) A156339E -> 1F7C12CD; default-config.txt = new templates
(Stellar E2EBF003, Onimusha 6309FEE5); custom-config.txt kept (53CCDB34); native-game-flags.txt untouched (Stellar AC8CFE14 still has
`DLSS5_MULTI_PASS=3`, so an F9 press there rewrites that line as well). Backup `D:\DLSSNR-Lab\multi-pass-skip-backups\20261003-144436`;
restore: `powershell -File D:\DLSSNR-Lab\deployments-multi-pass-skip-20261003\install.ps1 -RestoreBackup 20261003-144436`.

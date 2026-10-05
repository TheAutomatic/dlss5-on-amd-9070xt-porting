# Bounded real-game FFX input sequence capture

This isolated build captures original same-frame color, depth, motion, exposure,
reactive and transparency textures **before** neural mutation. It does not use
111.mp4, frozen input, generated motion or synthetic frames. Production source,
user config and installed addons are untouched by preparation/build.

## Build (CPU only)

`bash build.sh OUTPUT_DIRECTORY MINHOOK_SOURCE RESHADE_INCLUDE`

`prepare.py` patches only copied `native_submission_order_probe.cpp` and
`native_pre_upscale.h` in OUTPUT_DIRECTORY, then copies capture.h. The addon must
use the established FFX pre-upscale Mode2 (original FFX replay, no neural work).
Capture is called only in Mode2. Existing tail-of-list/terminal-state validation
is retained. No XeSS capture path is claimed.

## Runtime contract

An isolated staged configuration must choose `DLSS5_PRE_UPSCALE=2`; preserve the
player's original config outside staging. Set process environment
`DLSS5_REAL_SEQUENCE_DIR` to an existing empty directory on a >=100GiB-free disk
and optionally `DLSS5_REAL_SEQUENCE_FRAMES` (1..48, default16). Do not reuse a
completed directory. After the player reaches the actual roof scene, create
`ARM` in that directory. This code never starts or stops the game. Deployment
must use the project's game-idle/backup/readback procedure; build alone does not
authorize a hot replacement.

Capture allocates one readback per texture per frame and records six copies in
one owned list on the same DIRECT queue between the already submitted producer
and original FFX replay. Each input terminal state is restored immediately in
that list. A forced-deferred64-slot submission ring avoids per-frame Flush or
CPU readback. At <=48-frame burst completion a single Flush drains the copies,
then raw and JSONL are written. A frame-ID gap stops the burst; a GPU timeout
retains resources rather than assuming cancellation. `COMPLETE` exists only
when every frame and manifest have been written successfully.

Mode2 captures the FFX source contract; it does not run NR, so these frames do
not provide corresponding NR flicker output. Use a controlled replay to produce
that output from the preserved source. Start with 8–16 frames; 48 is a spare
upper bound.

There is extra GPU copy traffic, allocation overhead and a final disk drain:
this is an **instrumented sequence**, timing_valid=false. It cannot establish
natural-game flicker frequency or benchmark speed. Compare the same scene with
capture off/on visually before attributing a captured effect to production.
No every-frame GAME_PROBE Flush is introduced.

## Manifest / replay boundary

Schema `dlss5.real-sequence.v1`, JSONL: frame_id, monotonic timestamp_ms,
reset/jitter/motion_scale/pre_exposure/render/upscale/FFX flags, original source
states and all six resource roles. Missing optional roles are explicit.
Raw removes D3D row-pitch padding: row_bytes is GetCopyableFootprints' useful row
byte count, rows is copy-row count; width/height are full texture extents, render
is the independent valid domain. Copies preserve native DXGI bytes, subresource0;
no implicit decode or MV sign conversion. SHA sealing and real-sequence
validation belong to the shared validator supplied by the integration agent.
`config-lines.txt` records merged configuration source lines, not a claim that
all process-environment overrides are captured; archive effective override
values and module/addon SHA with the session before treating flags as complete.

seed=null: Mode2 does not execute the network or select its seed. The replay
seed must be explicitly specified and recorded by the replay harness. Likewise
motion_contract_verified=false: observed FFX scale/jitter are preserved, but
forward/backward sign and nonzero sample behavior require verification from the
captured data and original post oracle. Shader-sized texture alone is not that
verification. Depth/exposure formats must be decoded explicitly; optional
upscale [0,0] uses context max size, not a guessed output geometry.

A scene-matched capture is still required. CPU build success is not a successful
GPU capture, a complete temporal replay, or a repaired roof.

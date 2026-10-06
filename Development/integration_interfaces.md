# Optional integration interfaces (PR 12)

Based on upstream `297b032ac55f005d78568e684f30608651044f62`. All new
integration modes are opt-in. The addon now includes an explicitly opt-in FFX
pre-upscale Fast History consumer; its default rendering route is unchanged.
No end-to-end game validation or completed downstream release is claimed.

## Ownership and defaults

- `NativeGameCodec`, `NativeGameRgbInput`, and `NativeRgbTexture` accept
  `EnableReplayableRecording()` before creation. Only this mode changes their
  initial resource state and makes first/discarded/replayed recording barriers
  identical. `PinRecording()` adds references to the exact resources, descriptor
  heap, root signature and pipeline used by that recording. Callers release them
  only after abandoning the list or proving completion of every execution.
- `D3D12Bridge::EnableRecordingLeases()` opts into separate recording and
  execution. Record input/output, then `SealRecordedOutput()` after the last
  reader. Call `BeginRecordedExecution()` before submitting the actual producer,
  enqueue HIP after producer submission, and call `EndRecordedExecution()` with
  actual submission facts. Methods must be serialized. A completion signal
  failure retains resources. A queue change waits for the last actual consumer.
  Graph and input-poll modes are rejected for replay; legacy submission is unchanged.
- `RequestDirectHistory()` makes shared history writable. Producers leave it in
  COMMON; consumers use the bridge's existing semaphore/queue ordering.
- `RequestPostAuxiliary(row)` enables an additional raster logit output.
  `PostAuxiliary()` describes the resource, offset, capacity, processing dimensions
  and 8-byte pixel stride: FP32 logit followed by its half-RTZ diagnostic value.
  The row has exactly 32 finite coefficients. Unsupported layouts or missing exports
  fail explicitly. The actual selected norm900 module is checked too; no silent
  downgrade to a different numerical module. Without this request, allocation and
  dispatch paths retain upstream behavior.
- `SetAdaptiveReuseAllowed()` is instance-local and does not write environment
  variables or preferences. History callers must disable approximate reuse,
  including their priming frames. Existing addon hotkeys remain supported.
- Codec active width/height default to the whole resource. A smaller active area
  preserves allocation padding. `SetTypelessRgba16View()` sets one instance's
  interpretation before creation; the default mapping remains UNORM. R10 UNORM
  and TYPELESS both retain the upstream fallback through private FP16.
- The optional `NativeShaderCompiler` argument is scoped to creation/compilation.
  Providers own compilation, includes and caches. They bypass the default cache;
  there is no global mutable callback. No provider preserves the old compiler.
- `NativeFastHistory::History` owns shader-side histories only. The caller owns
  guide resources, immutable descriptor heaps and control-buffer contents through
  GPU completion, and supplies frame/reset/seed policy. It must not combine the
  helper with the reference experiment or ViT reuse.

## Validation completed on 2026-10-06

Run `Development/test_integration_interfaces.ps1` from an MSVC x64 shell;
`-Amd` also runs the synthetic GPU tests. Results go under `exports/`.

- Codec WARP: byte equality with the fixed upstream HDR/sRGB shaders, optional
  policies/debug flags, packed legacy formats, both R10 fallback routes and the
  actual addon conversion shader, fallback disabled in a separate process,
  rotated R10 texture rebind,
  active-area padding, discarded/replayed recording, independent typed views,
  concurrent compiler-provider isolation, History pipeline compilation.
- Module load fault injection: Style copy failure, missing optional API, load
  failure, absent optional constant, and successful ownership transfer.
- MSVC compilation of `Development/HIP/bridge_network.cpp`.
- Fast History WARP and RX 9070 XT: independent double-precision five-tap
  reference, different pre/post motion, edges, reversed depth, model feedback,
  reset/zero recovery, and reflected/partial workgroups through 3840x2176.
  These shader tests use synchronous uploads. A separate addon test pauses the
  GPU queue, records ten frames with independent controls, then checks deferred
  feedback, reset, gap and exposure behavior on WARP and RX 9070 XT.
- Four C32 recipes, both gfx1200/gfx1201: LLVM23.1.2, RowOpts,
  `-real-true16`. Existing kernel code and descriptors compared against the fixed
  upstream build: unchanged except relocation of entry offsets and PC-relative
  references to the unchanged Style constant; two new logit exports added.
- D3D12 debug layer was unavailable. gfx1200 hardware and full-network auxiliary
  output/replay were not tested. No whole-network speedup claim is made.

## Downstream adoption and validation boundary

The isolated downstream Runtime has been migrated to these interfaces and compiled
against the raw candidate headers: compiler/cache policy stays downstream;
History uses this helper; codec view selection and replay are per instance;
bridge history, diagnostics and retirement use explicit requests. This does not
advance the downstream completed upstream pin or certify all newly introduced
upstream defaults/modules. Full staged upstream review, matching module rebuild,
and downstream runtime/game verification remain necessary before adoption.

No promise of zero regressions follows from compilation. In particular, full HIP
network auxiliary output and replay/failure tests have not yet run against this
candidate. The synthetic tests are not a substitute for those checks.

## Addon Fast History

Set these restart-required flags explicitly:

```text
DLSS5_PRE_UPSCALE=1
DLSS5_FAST_HISTORY=1
DLSS5_TEMPORAL_MV_UNJITTERED=1
DLSS5_FAST_HISTORY_DEPTH_INVERTED=1
DLSS5_MULTI_PASS=1
DLSS5_HIP_GRAPH=0
DLSS5_OVERLAP=0
```

Use depth direction `0` for conventional depth and `1` for reversed depth.
The addon does not capture the FFX context depth flags, so it deliberately requires
this declaration instead of guessing. `TEMPORAL_MV_UNJITTERED=1` declares the
motion-vector convention; do not set it for jittered vectors. Only the captured
FFX pre-upscale path with a full network viewport is supported. The original
`TEMPORAL_HISTORY_EXPERIMENT` remains independent and cannot be combined with this
path. Non-HIP backends, incompatible post layouts/exports, graph/overlap and
multi-pass are rejected explicitly. To change to multiple passes, disable Fast
History and restart; the hotkey cannot silently keep one pass while showing two.

Generate `post70-history-head.f16` with the existing
`Development/HIP/experiments/post-history-gate/extract_gate.py` workflow and place
it beside the other model assets. It is the original 32-column model row,
promoted from half to float; this PR adds no weights or tuned coefficients.
Rebuild the C32 module variants to obtain the new logit exports.

The addon holds frame constants, descriptor heaps and motion/depth references
through its output fence. It resets on missing/invalid guides, frame gaps,
exposure changes and explicit reset; a missing-guide frame runs current-frame NR.
Approximate ViT reuse is gated for the entire Fast History session without
rewriting the preference. No history allocations or dispatches occur when off.
The helper exposes numerical parameters to other consumers, which own their own
reset, seed, guide conventions and UI policies.

Additional bridge services are also opt-in: `RequestReleaseMarkers()` before
creation, timing pause/epoch/tag methods, and prepared HIP passthrough for
transport diagnostics. Passthrough must not consume temporal input. Existing
input-poll/pulse behavior is retained; replay explicitly rejects input-poll.

The build script retains UTF-8 BOM for Windows PowerShell 5.1 parsing of its
non-ASCII comments; module recipes are unchanged.

R10 numerical evidence: candidate and unchanged upstream decoder outputs match
byte-for-byte on WARP and AMD. A direct format-conversion shader can differ from
both by one half ULP on AMD because the codec retains the upstream luminance
round-trip. The test bounds that difference and checks alpha exactly; it does
not alter the shader to force two different algorithms to match.

## Optional consumer policies

`Options::integration` defaults to the existing addon behavior. Consumers can
veto F8 polling or HIP input polling per instance without changing process-wide
environment variables. These are capability permissions, not new addon defaults.
`override_multi_pass_skip` supplies a parsed block set; when false, the existing
environment parser is used unchanged (no new `none` syntax).

The optional `select_module(stem, fast_numeric, module_directory)` callback selects module stems at
construction. It receives the resolved architecture-specific module directory and
the exact C32 RTZ candidate before the legacy twin
normalization. With no callback, the existing module selection and missing-twin
warnings are unchanged. Consumers own their module bundle's supported fast twins,
fallback checks and numerical policy; the callback must remain valid for the
network lifetime. No module recipe or default FAST0 output is changed here.

Explicit identity codec extents now use the same direct sampling as omitted
extents. This fixes the active-subrect interface's unintended 1:1 interpolation;
legacy callers with no active extents retain their original fit predicate.

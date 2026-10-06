# Optional integration interfaces (PR 12 work in progress)

Based on upstream `297b032ac55f005d78568e684f30608651044f62`. The existing
addon is unchanged. Fast History is a reusable, tested shader helper at this
stage, **not yet wired into the addon**. Do not claim end-to-end game validation
or removal of downstream source patches from these interface tests alone.

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
  active-area padding, discarded/replayed recording, independent typed views,
  concurrent compiler-provider isolation, History pipeline compilation.
- Module load fault injection: Style copy failure, missing optional API, load
  failure, absent optional constant, and successful ownership transfer.
- MSVC compilation of `Development/HIP/bridge_network.cpp`.
- Fast History WARP and RX 9070 XT: independent double-precision five-tap
  reference, different pre/post motion, edges, reversed depth, model feedback,
  reset/zero recovery, and reflected/partial workgroups through 3840x2176.
  These tests use synchronous control uploads, not the product replay scheduler.
- Four C32 recipes, both gfx1200/gfx1201: LLVM23.1.2, RowOpts,
  `-real-true16`. Existing kernel code and descriptors compared against the fixed
  upstream build: unchanged except relocation of entry offsets and PC-relative
  references to the unchanged Style constant; two new logit exports added.
- D3D12 debug layer was unavailable. gfx1200 hardware and full-network auxiliary
  output/replay were not tested. No whole-network speedup claim is made.

## Remaining integration work

1. Addon: carry FFX depth plus its format/state/ownership alongside motion;
   preserve per-frame control/descriptor lifetimes for deferred submission. Wire
   an explicitly opt-in fast path with supported-layout checks, seed/reset policy,
   missing-guide fallback and ViT exclusion. Keep the reference experiment intact.
2. Validate auxiliary output in the real network and bridge replay/failure cases.
3. Migrate the isolated product consumer, keep compiler and product policy locally,
   review the full upstream delta, then remove corresponding patches/preserved
   files only after a clean raw-source build and contract tests succeed.
4. Finish review before updating the existing PR. The current downstream official
   pin has not moved; this candidate is not an accepted upstream release.

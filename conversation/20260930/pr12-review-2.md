# PR #12 second review (2026-09-30)

PR head: e5a5d79c "Preserve codec defaults and complete R10 texture write-back" (on top of base 54e14de5; main is 116 commits ahead).
Note: the first-round notes file conversation/20260928/pr12-review.md does not exist locally; the first-round points are taken from the task brief.
GitHub API was rate-limited, so his comment replies were not read; this review is based on the commits alone.

## Status of the first-round points
- PDL preflight / TYPELESS switch: unchanged, still OK (TYPELESS defaults to UNORM, so Ronin is unaffected).
- ColorStrength default mapping: FIXED. The default is back to `lerp(original*ratio, upgraded, CS)`, the same formula as the base. The new curve only runs when `hue_safe` (bit 18) is set.
- preOnly white point: FIXED. It is now gated by `use_pre_exposure` (bit 17), which defaults to false.
- auto_white vs debug views: FIXED. The view is `Reserved.x & 0xFFFF`, and `ValidStrength` now rejects `debug_view > 4`, so flags can no longer be injected through the enum.
- R10G10B10A2 write-back: DONE. There is a raw-buffer 10/10/10/2 packing path, and `BufferFootprint()` is now the single source used by `CopyTextureRegion` in the runtime. It comes with a synthetic D3D12 regression test (not a game test).
- Default path: the new flags default to 0, and with all flags at 0 the shader and cbuffer logic matches the base code, so the default output should be bit-identical. We have not re-run it on our machine to confirm.

## Conflicts with main
- Textual: src/native_game_codec.h, 2 hunks. main uses `SourceView()` (the 0.38 format fallback) and the PR adds `r10_out`. The fix is to keep `SourceView` and add `r10_out`.
- Semantic, and the main issue: main's 0.38 fallback table already accepts R10G10B10A2_UNORM/TYPELESS and routes them through a conversion to private RGBA16F. The fallback is "consulted only where NativeIsGameColor() says no". The PR adds R10_UNORM to `NativeIsGameColor`, so after the merge R10_UNORM bypasses the fallback and takes the new direct write-back route, even when DLSS5_FORMAT_FALLBACK=1. R10_TYPELESS still goes through the fallback, so the two R10 variants would take different routes. The add-on/pre-upscale paths also branch on `NativeIsGameColor`, and they have not been checked for R10 direct handling.
- Other files (bridge PDL, reference network, runtime footprint) auto-merge cleanly.

## Verdict
Needs one more change before merging: rebase onto current main and pick one route for R10. Either (a) drop R10 from `NativeIsGameColor` and leave it on the fallback, or (b) make the direct R10 write-back the single route for both R10_UNORM and R10_TYPELESS, remove R10 from the fallback table, and cover the add-on path. The codec-default and PDL/TYPELESS parts could land first as a separate PR.

## Draft reply (English)

Thanks for the update. This round addresses all the points from last time. The legacy ColorStrength curve is the default again, pre-exposure-only and hue-safe are explicit opt-ins, debug views mask the policy bits, and R10 now has a real write-back path with a regression test. With all the new flags off, the codec logic matches the old code, which is what we needed.

One blocker remains before we can merge: main has moved on. On current main (DLSS5_FORMAT_FALLBACK, on by default, shipping in the next release), R10G10B10A2_UNORM/TYPELESS are already accepted through the fallback table, which converts them to a private RGBA16F texture. That table is only consulted when `NativeIsGameColor()` returns false. Adding R10_UNORM to `NativeIsGameColor` therefore silently moves R10_UNORM onto your direct route, while R10_TYPELESS stays on the fallback, and the add-on path isn't covered for direct R10.

Could you:
1. Rebase onto current main. `native_game_codec.h` conflicts: keep `SourceView()` and add `r10_out`.
2. Choose one route for R10: either leave it on the fallback, or make direct write-back the single route for both UNORM and TYPELESS (removing them from the fallback table) and cover the add-on path.
3. Optionally, split out the PDL/TYPELESS/codec-default changes so they can land now.

Thanks again, the test harness is especially appreciated.

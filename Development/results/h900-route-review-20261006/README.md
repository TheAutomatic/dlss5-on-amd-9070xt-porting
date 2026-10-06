# Independent H900 production-route CPU review

Reviewable candidate is prepare_route.py, not yet production source. No GPU or edits to math-owned files. abi-review.json independently parses actual F0/F1 ELF metadata: 26 kernel names identical; full argument lists, kernarg segment size/alignment, wavefront and required workgroup ABI fields identical. This verifies the gfx1201 candidate artifacts listed by SHA, not arbitrary modules bearing the optional filename.

## Required route gate

At review time constructor route checks only 15 hot exports. Eleven original FAST exports are missing from required[]: ten compatibility exports and c32_wave1_post_b8_features (see JSON). Root's whole-module fallback contract requires all 26 legacy exports, with CPU ABI identity bound to the shipped candidate SHA. Any missing file/load/export must unload the optional candidate and load the original module once; no per-kernel mixing. Current source does unload the failed optional handle before old load and binds only the selected handle to modules[c32_wave1]. No new user quality or environment key is needed.

Two apparent up_lb source exports are under CW_UP_LOW_BYTES=0 and are absent from both actual F0 and F1. They are not current legacy requirements. This corrects an initial source-only suspicion; adding them from disabled source would invent a payload contract.

Current route predicate: entry==c32_wave1, fast_numeric, W1600/H960, !experimental_temporal. It preserves other geometries/FAST0 and RTZ selection. It also includes graph/MP3/legacy history because those are not excluded. The hoist preserves math inside each call; that does not extend the measured performance scope beyond FAST1 full71 MP1 graph0 historyoff. If broad correctness permits those modes, explicitly report them as unmeasured performance scope; otherwise add conservative route exclusions without changing baseline settings. In no case route1152 to H: its framework +.074ms result remains negative.

## Identity and evidence boundary

prepare.py defaults CW_NORM_HOIST0; --enable selects1. F0 machine .text/.rodata/.note matches stock and F1 matches tested H, with private CUID/full ELF SHA differences documented in c32-norm-hoist results. Normal/RTZ current source adds optional postfeatures absent their historical payloads. Their macro0 stock-shape proof removes that optional export and shows old machine section identity; it does not make current normal/RTZ full ELF identical or provide positive hardware gold. The new production candidate is FAST-only, so no substitution of those normal/RTZ candidates is needed.

Unit gold and selected prefix/full-net evidence support arithmetic equivalence in tested contexts; common cold tap data cannot prove every legacy entry or all normal/RTZ paths. ABI identity is independent of runtime numerical coverage. gfx1200 candidates are CPU-built, target/resource locked only; no gfx1200 hardware test is claimed.

Before release acceptance, math's actual constructor-routing harness must log requested scope/selected filename/active state and actual prefix call for 19-case ghost on/off, plus missing-file and missing-legacy-export whole-old fallback. Identical outputs with no active-route receipt cannot prove this constructor route ran. On/off uses the same existing input/config recipe; do not invent a new quality switch. This review has no such runtime route evidence yet.

H900 round3 mean/p99 +.14 microsecond tail delta was audited against the actual 1-microsecond wall timer and judged equivalent within resolution (f38c3cb4); do not rewrite it as strictly negative. That scoped acceptance does not rescue the larger1152 negative result.

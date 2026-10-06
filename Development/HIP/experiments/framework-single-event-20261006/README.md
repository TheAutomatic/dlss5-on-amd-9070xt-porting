# Single timed marker framework control

Default-off isolated candidate: one owned timed event, one Record at the exact former C512-encoder-start point. No inner query/elapsed/synchronize, no kernel/codec/address change. Reuses the existing NativeGameFrame benchmark and current stock FAST1/full71/MP1/AE0/history0. Graph rejects in this isolation prototype. Create/Record errors still throw; this is not the production-safe optional helper.

`prepare.py OUT` creates shadow headers and benchmark. Build with MinGW C++17 (C++20 conflicts with existing u8string conversion). `run.ps1` performs only 900 none/single/single/none,160 frames discard80, same existing HDR source frozen every frame. Atomic GPU lock, game idle/RTC check,15s watchdog,D>=100GB,60s own-probe cap, no overwrite of measured slots. No deployment or player configuration changes.

Before each measured frame, host-only SetTimingTag(i+1) attaches identity to the existing timing enqueue; the same original Poll snapshot prints frame/tag/ready. ready means valid and tag==i+1. This changes no query count/location. tag was originally0; bridge tags never deduplicate/filter elapsed values, but valid is sticky, so old logs do not establish current-frame readiness. A failed readiness gate must not claim paired frame CPU-minus-GPU cause.

Mechanism basis: pair first screens had positive mean/p99 and query/delay controls were negative; paired formal1152round3p99 regressed. Fewer owned events/Record calls is an independent minimal submission control, not a repeat of the failed pair. Only a once short screen is authorized here; no position sweep or automatic extra heights on failure.

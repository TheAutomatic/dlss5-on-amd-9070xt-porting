# Locked mochi hardware-window calibration

Original d1185d2 `nr_graph.exe`/model/SPV/plan remain unchanged. Same common1920×1080 encoded input, processing1088/640tokens, Style1/seed0/full71/historyoff, `--host-boundary --reuse --chunk1`, warm80. No tool installation/GUI or player/config changes.

83819 no-capture two runs (2 measured passes each) exited0/released lock. Both final outputs match each other and fresh60566 mochi reference SHA624d9d1a…612;33,177,600B, allfinite/alpha1. **Only end output exists in the original exe; no first-before-warm read.** Actual log123 derives `steps.size()` (locked nr_graph.cpp:5402), and nrvk.hpp:1150–1158 records one dispatch perStep;1078–1110 reuses that commandbuffer and submits one complete pass at chunk1. This is123 executed model dispatches perpass, not123 API recording calls each frame or a proved RDP global offset.

Startup noise-field has separate dispatches (nr_graph.cpp:3672–3681), with fill/copy initialization outside model steps. Candidate9842=80×123+one estimated noise dispatch+one-based convention; startup/internal renderop offset remains unverified. Never reinterpret123 as layer count or claim complete frame alignment from this arithmetic.

3747 single capture exited0/LOCK_RELEASED. Same installed RDP CLI1.0.0/configuration as current HIP trace: dispatch candidate9842/count123, explicit render-op-count123, counter-collection; no instruction-tracing/shader-instrumentation. Original exe repeats2000 to remain alive for transfer. Final captured output SHA matches own no-capture/fresh reference; original-assets metadata unchanged. Driver logs set clocks peak and restored clocks; no independent hardware-clock query. Its8.014ms captured run is not normal native timing.

Trace23,268,071B/shab3637416…62d remains `/tmp/mochi-spm-20261006/trace.rgp` and `D:\DLSSNR-Lab\mochi-spm-20261006-capture\trace.rgp`. TraceConfig9842/123 and4 SqttData prove SPM+SQTT. Existing parser validates5296samples/interval4096 and every derived ratio by referenced raw counters; timestamp span956192 raw ticks has no established time conversion.

| Provider field | M window | Current HIP window |
|---|---:|---:|
| Memory unit busy (includes stalled) |90.236%|87.275%|
| Memory unit stalled |12.944%|19.784%|
| Write unit stalled |0.733%|0.879%|
| Instruction cache hit |65.075%|99.381%|
| Scalar cache hit |96.724%|92.605%|
| L0 cache hit |75.191%|77.317%|
| L2 cache hit |95.293%|96.863%|
| LDS bank conflict |0.505%|0%|

Memory busy/stall both divide by GPU command-processor busy cycles; busy explicitly includes stall. They are not whole-GPU utilization, mutually exclusive phases, compute share or DRAM bandwidth. Fetch667,457,920B/write1,123,773,664B include provider-described extra/cache effects; Local video memory bytes17,847,232B means Infinity Cache(if available) or local memory; PCIe0. Do not sum overlapping fields or divide by an inferred frame/time.

Comparison is limited to captured windows with raw fidelity checked. Frame/global-index mapping and same tool boundary remain open; no existing reader supplies gfx12 first/last/full function order. Ratios may suggest further diagnosis but do not establish where native1.046286ms gap lies. Actual device/provider/config comparability is independently reviewed; no recapture solely to force a desired conclusion.

# Current fullNN RDTS calibration (2026-10-06)

No production/config/install changes. This is a profiler-clock diagnostic, not native performance. Existing RDTS CLI 1.0.0 help/AST were checked read-only; no tool installation.

Pure HIP, same current full71 FAST1/MP1/AE0/Style1/seed0 encoded fixture, 1920×1088/640 tokens. The caller removes outer timing events/getters. Isolated host scalar counters cover ordinary/ext Run and all four direct SP API branches. It does not repeat individual kernels.

Count validation31928: cold161 dispatches; 80 warm frames end at13041; each subsequent frame161. First/final raw finite and bit-identical. SP_STATS166 stages across83 frames, no recovery replay/fallback; lifetime actual PDL calls0 despite requestedPDL1. No capture or clock changes in this gate.

Capture97053 exited0/LOCK_RELEASED. Candidate `dispatch:13042:161` plus explicit render-op-count161 and counter-collection, no instruction-tracing/shader-instrumentation. Same exe remained alive2000 frames for transfer. First/final captured raw SHA matches same-exe no-capture and locked stock (`153ac018…647f1`). Driver logs say set clocks peak and restored clocks; this is not an independent hardware clock reading. Trace33,416,059B remains `/tmp/fullnn-spm-20261006/trace.rgp` and `D:\DLSSNR-Lab\fullnn-spm-20261006-capture\trace.rgp`; hash in receipt.

RDF TraceConfig preserves start13042/count161. There are4 SqttData chunks, so this is SPM+SQTT, not SPM-only. Existing parser validates5763 samples and every derived ratio against referenced raw arrays. Candidate-window observed ratios: memory busy87.275%, stalled19.784%, write stalled0.879%, L0hit77.317%, L2hit96.863%, instruction cache99.381%, scalar cache92.605%, LDSbankconflict0. These include stalls in busy and are not percentages of frame time attributable to kernels. Available derived fields do not provide VALU/SALU or phase/wait categories.

**Mapping gate remains open.** Host API count is not yet proved equal to tool global render-op numbering (initialization/internal kernel offsets possible). No existing parser decodes gfx12 SQTT dispatch markers into first/last/full161 function order. Thus these ratios describe the captured window; do not label it a complete frame or infer a family bottleneck. Need an existing RGP event export/working SQTT reader plus same-host function sequence before resolving offset. Do not blindly recapture.

Old mixed D3D12/HIP trace changed outputs (`pipeline-gap-20260921/report.md:3`); its21.7%stall is withdrawn. Valid old pure-HIP repeated-kernel traces are hot-cache probes and do not supply this full-network attribution. Normal native gap1.046286ms remains a separate experiment.

# B2 direct half clamp, 2026-10-06

Isolated current FAST1 score helper representation; half conversion, half FMA coefficients, clamp endpoints and probability bits unchanged from B. COMGR21 actual 640 kernel: 68 VGPR / 12 SGPR / 0 LDS/private / kernarg32 / wave32, VALU213 versus B228; half conversions8+8 versus16+16. LLVM23 already folds B so its unchanged code is not COMGR evidence. No occupancy change (both allocation72).

Actual RX9070 161795 finite score/boundary gold: half_code_diff0. Full71 common encoded1920×1080/proc1088/640, Style1 seed0 MP1 AE0 historyoff,80 warm160 measured, first raw beforewarm, A/B2/B2/A. GPU8.902087/8.904425/8.899760/8.914308ms; pooled delta-0.006105ms, p99+0.054664ms. Both candidate slots do not beat both controls; weak short-screen signal, no production acceptance or next formal run. CPU separately raw-check.json.

B2 fullnetwork versus previous B raw bitdiff0 (same fixture); relative current A peak1 PSNR52.1965dB, maxabs0.0348168. This is selected synthetic baseline error, not image-quality acceptance. All finite and per-process repeat bit0. Finite CPU clamp comparison0diff; signaling NaNs excluded, all-code numpy probe1022diff documented; no original driver NaN claim.

Only helper changed; scalar/pair probe pair is static CPU evidence, not another network variant. Botharch COMGR receipts saved, actual GPU gfx1201 only. Whole fullunit other exports retain B mathematics; 400 also receives identical helper representation, no 400 performance run. No new deployment. Atomic lock/gamecheck/RTC check, D>=100GB,15s gamewatchdog; own run6448 exit0 LOCK_RELEASED. Binary/model/raw remain /tmp or D lab, not git.

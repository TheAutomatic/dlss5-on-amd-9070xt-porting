next-candidate (2026-10-02, source = main b6c508a5)  --  NOT installed. Run install.ps1 (-DryRun first) to put it into Stellar Blade + Onimusha.

What changes vs 0.39 installed:
  modules  62 = main's full recipe (hip/build-modules.ps1 -RowOpts -PrebuiltDir); code differs from 0.39 only in
           c32-wave1 + c64-wave2 (public LLVM 23.1.2, prebuilt on DGX; c32 also no post-RA + max-ilp) and c512-m32-deep (max-ilp), both arches.
  add-on   dlss5-amd.addon64 053C3589 = byte-identical to installed (host source unchanged since 0.39)
  runtime  LmxxfNrRuntime.dll 73D4C25C (RE9: reads DLSS5_STYLE from the flags file; default output unchanged, night-20261001 #1)
  shaders / flags: unchanged.

Validation vs 0.39 installed (lab next-candidate-20261002; same HEAD bench host both sides):
  19 groups SAME (7 cases x EXACT/AE x 12 frames + AE CSV + 900/1080 rollover, idle pinned)
  ABBA 900  -0.106 / -0.125 / -0.139 ms, merged p99 7.455 -> 7.332
  ABBA 1080 -0.189 / -0.180 / -0.176 ms, merged p99 10.347 -> 10.143
  Whole-net single frame (wall median / span median, ms, two passes):
    900 (1152 rows):  installed 7.403/6.898, 7.435/6.926   next 7.301/6.797, 7.317/6.809
    1080 (1152 rows): installed 10.163/9.624, 10.264/9.744 next 9.988/9.460, 10.014/9.464
    1080 (1088 rows): installed 9.844/9.299, 9.794/9.286   next 9.684/9.153, 9.704/9.162

Update 2026-10-02 (results/llvm23-vit-20261002 section 5): c64-wave2 (both arches) rebuilt with HIP_BARRIER_FENCE 1
  (recipe row l23defines). LLVM22/23 no longer insert s_wait_dscnt before gfx12 split barriers, so a bare s_barrier
  after LDS writes can race. In the old LLVM23 c64-wave2, 72 kernels had ds_store -> s_barrier_signal with no wait;
  all are mh_* kernels compiled into the module but NOT dispatched from it (the dispatched c*_wave2* / c256_attn_wave*
  kernels had none and are instruction-identical after the fence). c32-wave1: 0 such sequences, unchanged.
  New c64: 19 groups SAME; ABBA vs previous package 900 -0.002/-0.007/+0.022, 1080 +0.017/-0.003/-0.004 ms (A/A noise,
  dispatched code identical). Previous package backed up to D:\DLSSNR-Lab\next-candidate-bak-20261002-prefence.
Details: Development/results/next-candidate-20261002/README.md, Development/results/llvm23-vit-20261002/README.md

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
Details: Development/results/next-candidate-20261002/README.md

# Actual PAL V transpose-load mechanism: correct, tail-negative, STOP

New scoped mechanism comes from actual matched Mo PALVT shader:2global_load_tr_b64 V fragments, unlike current16global_load_u8+pack. Mo physicalV is blocked16×16; currentHIPV remains plane-major tokenstride1024. We did not change producer, query16 tile, Q/K/P/den/AV mathematics or resurrect physical transpose/M32 experiments.

## Address/byte evidence

Primary Mesa load-transpose lowering (math1008285e/a8dd7d6e): byte8 readrow=floor(lane/8)*4+(lane&3), readcol=(lane&4)?8:0, row multiplied by arbitrary memorystride. Source lane supplying output(lane,e) is floor((lane/16*8+e)/4)*8+((lane/16*8+e)%4)+floor((lane%16)/8)*4, byteoffset=lane%8. CPU equality maps every desiredV[key+lane/16*8+e][head32+c16+lane%16] to AoS1024 addresses. Base16aligned, perlane8aligned;全32lane active and full16keys. Official builtin exists in localLLVM23 and AMD docs https://rocm-handbook.amd.com/projects/amd-rocm-optimization-guide/en/docs-1.0.0/compiler-builtins/rdna/rdna4-wmma-transpose-builtins.html; its published b128 diagram is not substituted for undocumented b64 routing. Final routing is grounded in Mesa and hardwaregold.

Unit34829 localCPUcompile exit0;50448 singleGPU bytegold exit0/LOCK_RELEASED. Non-symmetric QKV bytepayload204distinctcodes,640tokens/key16/head7/two16channeltiles, oldCPUbyte_diff0/trCPUbyte_diff0 for512 raw bytes. This is one fixture, not all hardware inputs. Host/module/payload SHA and raw1024B retained. No WMMA or performance in unit.

## Sole main replacement and canonical compiler

prepare_main.py changes only transposed-score templateV load under MAXT640&&ByteInput&&ByteOut. Other77 exported functions remain original. Uniform first/reusegate and key0..624 step16, no tails or perlane conditions; newCOMGR ISA noEXECwrite/saveexec. Mainfirst localLLVM78128 failed on nonexistenttid() helper (log retained); corrected only to workitembuiltin, not a mathematical failure.

Canonical83565 COMGR21 old/new compile exit0/LOCK_RELEASED proves this toolchain accepts transpose builtin (no fallback/newcompiler). Old entireELFSHA11a25ae3fea75f83763ab6d5729c4f426dabda11299d1be6092d142b810e27b8 exactly actualstock; new965f9348f3f689a4b63e33140a75e5649dbdff604e6a6a7edcae8e830847b36f.78exports noABI differences; own instructiontext and math independent rawSTT_FUNC comparison match all77 other functions. Target16u8→2TR, VGPR68→62, SGPR12→10, LDS/private/spill all0. Metadata count decrease is NOT an occupancy claim; allocation granularity can keep both72VGPR.

## Complete NN correctness, receipt failure retained

21405 old/new each2run1920×1088/commonencodedgradient/full71FAST1MP1AE0historyoffStyle1seed0; self-repeatbit0/finite succeeded. Script exit1/LOCK_RELEASED only at finalreceipt asking old-canonical filename instead of actualold-comgr. No GPU retry: CPUexisting4rawSHA all153ac018f5dd5744cff9157661c46c469d01db6018a97c93aec2b1e2e05647f1 equals historicalstock. Existinglogs and whole-readback.txt preserve failure and actualdata pass separately; script corrected receipt names for future use. No output/input/producer/math change.

## One firstscreen, STOP on tails

24057 exit0/LOCK_RELEASED, exactlyABBA1088/640tokens. Firstraw before80warm,160timedframes eachslot; all8edgeSHA same/finite. GPU avg/p99 ms A0 8.879091/9.0306766;B1 8.851143375/9.0822906;B2 8.852035375/9.0697684;A3 8.89419225/9.0900672. Wall A0 9.0458875/9.28223;B1 9.0522375/9.44716;B2 9.0254375/9.31882;A3 9.05268125/9.33227. MergedGPUmean−.03505225 butp99+.0320382;wallmean−.010446875 butp99+.02385. ControlA0→A3 mean driftGPU+.01510125/wall+.00679375, B1wall slower than A0. Average improvement does not mean overall performance acceptance.

Root裁停: correct byte mechanism retained as experiment, no formal/APP/integration/refresh/productionconfig/install/package/push. Do not subtract thisdelta from the~1.046ms Mo gap or infer occupancy. Reopen only on new actualISA/dependency evidence, not samevariant reruns. All4slots/CSV/logs/rawhash/control drift kept under nn1088-firstscreen. Allprocesses terminal, GPUlockreleased.

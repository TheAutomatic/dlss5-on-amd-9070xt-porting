# Actual dispatch sequence and organizational differences

HIP89772 and M15597 small gates exited0/released sequentially. No profiling/outer GPU events, no production/config/installed changes. HIP first/last outputs match current stock reference/finite; original M `--wiring --warmup1 --repeats1` final matches M own reference, original assets unchanged. HIP module-manifest exactmatches fresh60566; opaque handle values were not printed.

HIP collector logs161 **first cold-frame** actual API call keys after module/kernel remapping, before ordinary/ext Run and four direct SP API sites; print occurs after frame completion. Fn cache maps actual:name to GetFunction handle (hip_reference_network.h:350–352), and norm900 is inactive at1088. It is not an SQTT pipeline-address map. Warm/last counts remain161 but names were not separately collected at steady state. Raw labels are function context, so the final post70 call inherits a block69 context label; semantic alignment uses actual callee/graph edge rather than that label alone.

M `--wiring` is only a print branch at locked nr_graph.cpp:3827–3836; it is absent from slot-reading-diagnostic/persist degradation flags. It prints final disp order;4014–4019 creates steps from that order (NR_DUP empty), and nrvk.hpp:1158 records one dispatch perStep. Commandbuffers are replayed at chunk1;123 executed steps perframe are not123 vkCmdDispatch recording calls everyframe. Two printed push uints are opaque until each kernel ABI is decoded, not generic buffer addresses.

| Semantic region | HIP | M | Extra |
|---|---:|---:|---:|
| C32prefix..4 + pool |6|5|+1|
| Encoder C64 5..8 + Down |5|1|+4|
| Encoder C1289..14 + Down |7|1|+6|
| Encoder C25615..22 + Down |6|1|+5|
| C51223..30 + head/gather |34|33|+1|
| ViT31..38 + reverse gather |49|40|+9|
| Decoder39 |1|2|−1|
| C51240..47 |32|32|0|
| DecoderC25648..55 |6|1|+5|
| DecoderC12856..61 |6|1|+5|
| DecoderC6462..65 |4|1|+3|
| C32up66..post70 |5|5|0|
| Total |161|123|+38|

M actual persist logs confirm encoder4/6/8-layer runs ending DS; decoder8/6/4 runs include preceding UPS. Source nr_graph.cpp:3160–3217/3348 preserves these dependencies, not merely ordinal matching. HIP C256 uses inner16..21 and49..54 only, each init/run/recover three API launches; recover launches even when replay/fallback0. Outer bodies/Down/Up remain separate. M persistent still globally publishes window tiles (`fswin_t.comp:2929` memoryBarrierBuffer/releaseL2), so one kernel does not mean all intermediate values stay in registers.

HIP each inner stage has6 separate FP8 output buffers (`swin_persistent_network.h:56–60/104`),120×68×256 bytes each =12,533,760B storage perstage. This is allocation footprint, not measured DRAM traffic; halo loads/cache/recovery prohibit deriving traffic from the count.

## Old-negative scope and one precise static feasibility point

ViT extra9 are8 input-pack kernels and one reverse-gather. Producer packing P/G/Q/R (`fusion-round3-20260928:58–70`), consumer float-load/inline-pack V (`deep-layers-20260929:61–64`) and gather fold G (`gap-fusion-20260930:25`) already failed; dispatch counts alone do not justify rerunning them.

SP_SMALL old negatives (`swin-persistent-c128-c64-20260929:7/31/61`) tested inner4→3/2→3 on d7b29df2/old completeAPP/old recipe, not currentW16/FAST1 pure1088 or M whole-stageDS/UPS fusion. W16 was added9/30; current function names/resources/geometry differ. Thus do not claim they are exact current-profile repeats, but changed conditions alone are not new positive evidence.

**Current SP does not directly feed Down.** Actual chain is SP16..21→Body22→Down; do not add Down to SP21 or silently expand SP to22/recovery.

One physically feasible but unimplemented point is Body22→Down: Body22 owns8×8 raster window,256threads/8 head waves cover all256channels; shift2 yields sx0/sy4, both even, so each valid2×2 raw group fits one producerwindow and its16-query qt. Down is2×2 pool plus256→512 projection, not merely pool. Exact consumer chain at multihead_fast_padded.hip:412–425 is top=H(a+b),bottom=H(c+d),p=F(H(H(top+bottom)*.25)); twoK16 WMMA perK32 chunk thenH(acc+sum), finalF.

**Actual math/module split:** c64-wave2-fast SHA65848e8d…5c799 has W2_FAST_NUM3. Body22 raw?3 callsHrtz but effectiveHrtz is identity (`multihead_fast_padded.hip:162–166`), so it stores fullF32 result. Down's FAST twin is actually missing (stderr:4); it loads normal multihead-fast-padded-wave-packed SHAe452eedb…ad6130, H has RNEhalf narrowing/expansion. Preserve distinct helpers; do not silently supply the missing twin or call all Hrtz outputs half-valued. SP SHA520cd2fe…c89df3.

Original Down groups16 consecutive pooled raster tokens and can read several producerWGs. Appending that existing helper inside Body22 without new mapping would be unsafe. A window-local4×4 pooled tile could use an independent16×264 half LDS array (8448B estimate), preserving exact per-channel/tile math. Border validity follows producercropping; no negative mirror-output writes. Need actual LDS liveness/register/barrier/resource and raw/pooled/output gold before any implementation claim.

At120×68, Body work120×72 has135 producerWGs; standaloneDown60×34 uses12816-tokenWGs. Naive window epilogue would issue135 projection tiles, +7/+5.47%, including120 invalid pool slots from sy4 cropping versus8 standalonepadding. Body22 raw remains skips[3] used by decoder48 (hip_reference_network.h:794/805); cannot delete its buffer/write. Only consumer reread/one dispatch might be reduced, with no predicted benefit.

Old resample-fold-20261001:3 tested C64/C128 window-tail fence+raw reread, repeated A construction, no tail LDS; all three rounds slow. C256 was explicitly inferred, not measured. A register-to-pooled-LDS C256 design differs in supply organization but is not evidence to reopen old variants; math agent owns subsequent CPU design. No new fusion kernel or GPU experiment was added here.

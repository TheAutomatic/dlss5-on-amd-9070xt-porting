# Actual APP eager/replay performance: source fairness review

Read-only `/tmp/graph0-app-perf-20261006/{benchmark.cpp,hip_reference_network.h,hip_d3d12_bridge.h}`, ownere05173fe. No reviewer edit/build/GPU. **Source pass for the current singlefour-slot ABBA**, not hardwareperformance acceptance.

The benchmark.cpp is unchanged from the originalFrame caller. It restoresHDRoutside timer, measures ProcessSubmittedFrame plus originalFrame drain, then records elapsed. edges_only1 performs D3Dreadback only at first/last and outside elapsed;160totalframes discardfirst80 gives80steady samples per slot. Do not transplant pureNN160steady/3readbacks into this APP protocol.

Bothmodes use identicaloriginalcodec/interop/NET0/historyoffMP1AE0seed0/PDL0/pulse0/fixed1152 recipe. Firstframe performs common boundedallocation/cachewarm in both modes; graphmode's capture+DAG/instantiate costs are separately logged and remain in firstdiscardedframe. Setup differences are followed by80Frame warm samples, not subtracted from steady rows.

Afterready, helper checks scope/aliasstablepointers and performs either ordinaryEnqueue or GraphLaunch; no getenv/Fnvector/lastFnstore/printing occurs in hot helper. LabLaunch retains only the explicitlab_record boolean branch whenfalse. Graphowner/plans/weights/pool/importmaps remain as the reviewedgold path; normalFrame/copyencode/decode/prewait/postsignal/D3Dwait/postSignalQuery/drain are unchanged. No newNet timinggetter/poll/outerHIPtimer is introduced, and this is not a zeroAPIwork claim.

ExpectedgraphlaunchAPI160 versusordinary0 is printed only at finalcleanup; APIcounts/fixed161nodeDAG are not hardwaredispatch/OSsubmission counters. Normalresourceclose and failureprocess-stop policy are unchanged; no furtherproductioncompatibility matrix is required for this source scope.

Originalelapsed code has no inlinefinite/positive assert, to preserve itsbyteidentity. Executionowner's CPUanalysis must validate all160numericwall rows finite/>0 beforemean/p99, and rejectinvalidbatch withoutrepeating. Driver/clocks andsamebatchcontrols are runtime evidence, not constants promised by source. first/lastraw must be finite/exact to actualFramegold, setupcounts/maps/loadedmanifest/SPerrors andgraphlaunchcounts must be checked. No existingpureNNdelta is added or deducted fromMgap.

PriorAPPgold19487/85abc115 actuallycompleted4boundedwarmstages (209→213→213→213 malloc,23→27→27→27 pool),161node/160edgegraph and12changedHDR F16gold outputs exact/finite withstableimports. This supersedes previouspendinghardware wording but does not establish the newperformancecaller result. Original70977 prerequisitesfailure remains unchanged.

Actualexecution update535eab68/37548: singleABBApassed, wallmean−0.074325/p99−0.07518ms, bothcandidatefaster; controlmean/p99drift+0.011963/−0.07324ms. All640wallrowsfinitepositive and8F16edgeoutputs exact/finite; graphAPI0/160/160/0 andquietrecordgate passed. NoformalR2/R3 outcome or productionpulseauto interoperability asserted at thisupdate.

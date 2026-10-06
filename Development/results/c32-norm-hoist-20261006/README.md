# C32 original-layout norm inverse hoist first screen

2026-10-06 only candidate H: unchanged QKV operand/K0K16 sequence, unchanged half(squareFP32) and two f16input FP32accum WMMA, unchanged scale/multiply/half/FP8 order; reuse rsq(max(sum[0],eps)) perlane. No QKV transpose/DSrestore/newLDS. A rebuilt canonical WindowsABI/C++14/-real-true16/rowopts/BCinternalize/link byte-identical stock f46b8af2…ee52. Models/all201assets andstockmodulemanifest/commoninputSHA checked beforeGPU; output source-payload-sha/expectedassets/modules locked. Source profile full71FAST1MP1AE0historyoffStyle1seed0, syntheticencoded1920×1080 mirroredproc1088. No runtime noise-cache modification.

Actual prefix ISA instructions1517→1480, rsq16→2, DS23same, LDS4096same, VGPR128same/0spill. HIP actual occupancy queriedmapped/prefix/post A/H all16blocksperMultiprocessor. No occupancy improvement claimed.

Eight hardware unitfixtures zero/signedfinite/signedzero/50overflowboundary/widefinite/+Inf/-Inf/255.9375vs256 squares boundary: rawQKV/square/sum/inverse/normfloat/FP8 everyword0diff; all8Csum elements bit-identical perlane gate in bothbranches, includes selectednonfiniteoutput cases not universalNaNclaim. Trueprefix actualmodelweights/FFN/commoninput firstwindowqt0Q trace12416bytes exactA/H; all8sum vec gate0 andnumericfinite; oncefull71 firstoutputSHAequal. Selectedsample, not allgameframes/originalNVIDIAgold.

First attempted93415 completedoccupancy/eightunit butprefixargc mismatch (CLI inherited PH-only while PS passed W+PH), no prefixkernel/timing; fixedharnessparameter, preserved this failure explanation. Corrected12716 exit0 LOCK_RELEASED,15sec gamewatchdog/atomicguard/D>=100GB.

A/H/H/A80warm160timed firstreadBEFOREwarm, no midscan:8.901741/8.839896/8.844241/8.904607ms; pooledGPUdelta−0.061106ms,p99−0.024127ms, bothHslotsfasterthanbothA. CPU separately independent-raw-check. Allprefix/fourprocessfirst/lastwholeNN SHAidentical/finite/repeatbit0, PSNRinfinitevsA. No formalacceptance/no othergeometry/no defaultdeployment. ReturnedGPUqueue to integrator. WeakB2/C2 gains are not added tothisgain.

## 900 first screen

Root-next900 window after safe1152 release: session53444exit0LOCK_RELEASED. Same tested plainH, realprefixcapture caller expanded W/PH only; sixoccupancies16, eightunitgold/all8sum0, actualprefixtrace/wholeNN first0.1600×900encodedsyntheticgradient mirroredproc960 token400, not HDR/gameinput. Allallfourfirst/last plusprefixwholeNN hashes equal. A/H/H/A6.651658/6.595973/6.602872/6.658025ms, GPUdelta−0.055418875,p99−0.0373776, bothHahead; CPU separate900-firstscreen/independent-check. No formal or broadsequenceacceptance yet, no deployment.

prepare.py now default macroCW_NORM_HOIST0 negative, --enable positive; tested plainH source has equivalentmacro1code. Do not regenerate default0 and labelcandidate. Canonical F0 .text/.rodata/.note exactstockA; F1 same sections exacttestedH. Full ELF SHA differs only private__hip_cuid buildsymbol/string/hash tables; exportedkernels/machine/resource unchanged. Normal/RTZ currentcanonical has extra optional postfeatures export absentstagedstock, so not wholemoduleidentity bydefault; negativeoldexportshapecheck pending, no normal/RTZGPUproof.

## Multirow CPU scope

Currentnormal/RTZcanonical source adds optional post_b8_features export absentstagedoldnormal/RTZ, so wholeELF differs. Removingonlythat uncalledexport for macro0oldshape yields .text/.rodata/.note exactstagedstock in bothrows (normal-rtz-stockshape-check). Normal/RTZ positive current-source candidates keep optionalexport and samelegacykernelABI; no hardware19-caseproof yet. gfx1200F1/N1/R1 CPUbuilt/ELFmetadata locked dualarch-cpu-candidates; no actualgfx1200deviceclaim. Machine-scope negative proofs exclude private__hip_cuid label/hash tables; totalSHA differences documented.

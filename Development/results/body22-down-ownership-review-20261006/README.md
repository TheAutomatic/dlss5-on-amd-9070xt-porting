# Independent CPU Body22+Down route review

Only actual experimental generatedheader /tmp/body22-down-local-route-20261006/Development/HIP/hip_reference_network.h and goldhost reviewed; math owns implementation. No edits to those files/GPU/process interference.

Normal route: Body22 exact120×68/work120×72/shift0,4/rawpost3/byteinput/w16 known1088 scope stores strong dl_input/dl_raw references and borrowedFW/AWcache pointers, returnsrawTensor without launchingoldBody. Maingraph retainsrawskip3 beforeDown. PendingDown checkssameTensor/raw andnormalC256geometry, createspooledout whileinput/raw stillstrong, resolvesDWcache, launchesone newexport135groups×256threads/13args80B onownedstream, then clearsrefs. Subsequentpoolreuse is protected byordinarysame-stream commandorder. Oldpath remains whenmodule/eligibility absent; unexpectedpending overwrite/Downscope failsclosed rather than silently using uncomputedraw. Weights areNetworkcache-held throughout. Stage observers are not part of the known rawchain diagnostic profile.

ABI matches: input/FW/AW/raw pointers offsets0..24,7u32 offsets32..56,DW/down pointers64/72,80B total. Shadowgold hook runs afteractualoldBodyAPI whilearguments/localTensors arelive; ownD2Dsnapshot preservesinput beforeallocatorreuse. ActualoldnormalDown reference validatespointeridentity/60×34/srcwidth120/valid0 and synchronizes before reads; candidate uses separate raw/down buffers, does notfeedstockgraph. Shadowvalid2040pixels do not alone proveallocationcapacity.

Two concrete route defects found and fixed in actualsource: fusedDown originallyNew(2040×512) unlikeoldNewPad16. NowNewPad16(2040,512) retainsvalidbytes4,177,920 andcapacity4,194,304 (2048tokens), soCompactC512Body548 does not insertmh_shift_pack duecapacity<2048. This explains fusion savingoneAPIbut addingonefallbackAPI, not a phantom counter. Dispatchcounter increments insideactualRunlaunchloop orafternewfusedAPI; no counter beforeBodyearlyreturn.

Correction to initial review wording: originalNewPad16doesNOTclear8paddingrows. It roundscapacity andchangeslogicalbytes; onlydiagnosticPOISON macrofillsff. Preserveexacthelper/capacity/poisonsemantics, do notintroducezeroing. The comment says paddedrows remainrow-independent andvalidattention/output boundaries; unnecessaryclearwouldchangescheduling/performance.

Seconddefect: pendingTensors declaredbeforeApi woulddestructafterApi onexception. Actualdestructor nowstream-synchronizes whileApi isalive andunconditionallyresetsdl_input/dl_raw/flag/borrowedptrs wheneveranyrefsremain, beforepoolclear/API destruction. Coversaweight-lookupthrowafterrefsassignedbutbeforependingtrue. Normalpostlaunchreset is unchanged. No requestforadditionalproductioncompatibilitytests; knownsingle-thread/one-device experiment only.

ActualsourcefixSHA retainedsource.json. Math's99187shadowraw/down0 andsubsequentwholeNNruntime gates remaintheir own evidence; this CPUreview doesnotclaim additionalGPUtesting. No kill/restart/install/config/push.

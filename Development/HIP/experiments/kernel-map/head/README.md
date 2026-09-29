以下为候选设计记录；最终编译、逐位、计时和部署结论见 `Development/results/kernel-map-20260929/README.md`。

# C512 head pool/grouped FP16 projection

Independent baseb99e9ef6. Candidate reuses existing `mh_pool_project_group_body<512>`; no new arithmetic code. Append `c512_head_group.inc` to experimental **multihead-fast-padded-wave-packed** source, define `C512_HEAD_GROUP=1`; host patch default0 `C512_HEAD_GROUP_HOST=1` extends only Down(...head=true,c512) through existing grouped route. All other layers and diagnostic configs retain prior behavior.

New export ABI is existing pool-group ABI `(raw,PackedDsWeightFrag,output,ow,oh,source_width,valid_width,valid_height)`. Existing Run prefix parser recognizes c512 automatically:512threads,gridceil(ow*oh/16). No module remapping needed. Don't append just to c512-m32-mh unless also changing hostmodule routing; current patch deliberately calls mh_fast.

## Same position, different math

Our head is pool2×2,then512→1024.1080 produces32×20slots but only30×18valid;90025×16slots,25×15valid. Daniel head dispatch hasFP8 WMMA (BD A88 etc),packed-byte input from prior pool-output conv. Its lower timing does not establish a drop-in arithmetic equivalent. We explicitly keep all currentFP16 operations and original valid-pixel masks.

Original ours projection: one wave16tokens×16outputs;64column groups independently reload each pooled row. Its weight fragments are half row-major,16bytes/lane spanning512-channel rows. Per32-channel chunk has twoWMMA thenH(acc+sum),repeated16times. This rounding structure is preserved exactly.

Candidate: one group16pooledtokens,512threads=16waves,eachwave64outputcols. Pooling occurs once into `pooled[16*(512+8)]`half LDS =16640B. PackedDsWeightFrag rearranges the same RNEhalf weights into contiguous16×16 fragments. Each A fragment feeds fouroutputtiles. All1024outputs still receive the original K32H reduction chain andF at store. Pooledzero border and outputzero border preserve original valid_width/height handling. Raw→pool H(top),H(bottom),F(H(H(top+bottom)*.25)) identical to existing mh_pool.

1080: old40*64=2560projectionwaves +pool; candidate40groups*16=640waves,each4×work, removes one dispatch.900:25*64=1600projectionwaves→25groups*16=400waves. TotalWMMA pervalid/padded output area stays unchanged; pool work no longer repeated across waves,pooledglobalbuffer removed,halfweights read withfragmentlayout. Stronger reuse may compete with coarser group scheduling andLDS; no speedclaim until compile/resource/bitwise/timing.

This is not the rejected C64/C128 Down-tail fusion: those attached an extra tail to attention and paidfor longerblocklifetime; here existing head currently has two standalone kernels and we simply enable the already-used groupedpool+projection shape forC512. Also not rejected C512 FFN M32; noFFN hidden/activation involved.

No production change, compile or GPU run performed here. Default0 baseline verification plus existing7EXACT/AE cases and two-tier timings remain required if shortscreen wins.

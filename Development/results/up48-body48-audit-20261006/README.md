# Up48 → ordinary Body48: CPU contract audit

No implementation/build/GPU work in this audit. Actual frozen sequence is Up(block48weights) → Body48 → SP49..54(init/run/recover) → Body55, not Prefix49/SP50..54. Sequence161/123 original logs and module manifest are in ../dispatch-sequence-20261006.

- Up callee `decoder_project2x_h16w_byteout_w`: deep_fast-packed-fast SHA11a25ae3fea75f83763ab6d5729c4f426dabda11299d1be6092d142b810e27b8.
- Ordinary Body callee `c256_wave2_bi_bo_w16`: c64-wave2-fast SHA65848e8d21ef4e647ff9c1f995415676ca47d669610354b7c6743e745525c799. Current W16/FAST3 recipe remains the reference; no compiler mixing or missing-twin replacement.
- Host hip_reference_network.h:782/803 limits existing fusedUp to g>0(C64/C128);805–807 show separate C256 Up48/Body48 and unchanged SP49..54. Shader exports wave_owned_mh.inc:812–823 likewise provide Up only64/128. No C256 same-boundary trial found in prior results.

## Exact current value boundary

Standalone Up source deep_fast.hip:517–529 uses input512, output256, K16 FP16-input/weight WMMA with FP32 accumulation (onepart at512), then `t=H(total)`. H is explicitRNEhalf→float at:53; VITFAST15 does not replace this generic UpH. For each high-resolution pixel/channel, `merged=H(t+F(skips3)*scale)` with original separate FP32 product/add; HIP_BYTE_F_ADD01 selects `fp8_add0(merged)` (:236–241), followed by FP8 byte conversion. Keep this exact half merge/zero/saturation boundary; it is not permission to keep unquantized Up result in the Body.

Body48 ByteIn uses decoded identical UpFP8 bytes for its FFN and residual. All256channels must be available to the cross-head matrix operations, **not an entrance256-term normalization**. Q/K norm is eachhead32 serial square/add order (wave_owned_mh.inc:204–216/592);8heads independent. Residual at:528–537 reads original input bytes and preserves w2_rtz8/products before original mixing. Body48 outputpost0 and existing packing/masks stay unchanged; no new mathematics/precision option.

Existing Up=true template constructs plane0 bytes and reads them in its input/residual paths (:272–278/528). Its merge uses generic BodyH, which is identity under FAST3, whereas this standalone Up must use normalRNEH. Thus adding a C256 export of the current template alone is **not a proven lossless integration**. A limited new variant needs independent UpH/byte epilogue, leaving BodyFAST helpers untouched. W2_UP_VEC's total narrowing is already explicit, but merge still requires this separation.

## One feasible supply mechanism, pending static/gold gates

At processing1920×1088, Body48w120/h68 and shift(48)=0 produce work120×72. One256-thread/8wave WG owns8×8 high-resolution pixels, can project its own4×4 low-resolution patch from all512input channels into complete256channel bytes in plane0, then execute ordinary Body48. All dependencies are local or readonly low/skip/weights; original byte representation is staged before the existing WG synchronization. No cross-WG Up result reads are required.

Bottom partial windows must zero the same high-resolution padded rows as original ByteIn. Global Up intermediate120×68×256=2,088,960B has only Body48 as consumer and can in principle avoid materialization; **skips3 raw remains a required Up input**, stored across the intervening encoder/deep/decoder sequence. Do not delete or half-convert it. Body48 output feeds SP49..54 exactly as before; no SP layers/recovery change.

Window-local low4×4 tiles give135 WGs versus standalone128 flat16-low-token groups (60×34 validlowtokens). The straightforward local projection performs135×8waves×2channel16tiles×32K16=69,120 WMMA tiles versus128×16channeltiles×32=65,536 (+5.47%). This supply mechanism avoids rereading global Upbytes but adds boundary padding/work and potential registers; existing bodyLDS may be reused only after liveness/source proof, not claimed free. No predicted milliseconds or wholeNN win.

## Prior negatives do not establish this exact result

- c128-c64-inchain-20261001:61–68 UP_DIRECT computes projection at high-resolution columns,4×MMA; three rounds slower. Keep default0; this local low4×4 mechanism does not reactivate it.
- w16-c64-c128-20260930:3 is small-channel W16 organization, not C256Up→Body48.
- swin-persistent-c128-c64-20260929:45 preserves fusedUp prefixes and tests only interior stages; no equivalent C256 boundary proof.
- c256-fusion-20260928:64 tests block-body fusion and explicitly retains standalone decoderUp, not Up/body merge.

Only one CPU candidate is warranted: same loaded recipe C256 window-local Up→Body48 with independent UpRNE/byte contract. Required gates before execution: original stock regenerated identity/ABI, newexport-only machine diff/resource no-spill, Upbytes/fullBody output/intermediate residual gold over interior and bottom border, unchanged SP and own fullNN correctness. This audit is feasibility/history-scope evidence, not acceptance or a reason to rerun old failed variants.

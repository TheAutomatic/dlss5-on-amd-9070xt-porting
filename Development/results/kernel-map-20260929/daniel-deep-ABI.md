# Deep reference microbench jobs (synthetic only)

`daniel-deep-jobs.json` preserves every row of deep-schedule.csv:324 rows,3 geometries,21 actual symbols. It does not replace external-input/boundary/pool/split variants with the ordinary symbol. Native900 is52×32C512,448ViT; native1080 andmatched1080 deep shapes are60×36,640ViT. Each job is independent: immutable finite ±.25 input and ±1/64 weights, zero output; there is no claim of actual model output equivalence or end-to-end latency. Packed random finite values are invariant to unknown intra-matrix permutations statistically; all known scalar/half regions receive typed initialization.

## Generic launch contract

Actual user-prefix bytes come from the ELF AMDGPU msgpack note, stored inall-metadata.json. The runtime must provide implicit dispatch fields after the user argument prefix; do not append guessed trailing zeros to a metadata-sized kernarg. All jobs supply one packed by-value argument buffer through HIP extra; offsets are byte offsets inside that prefix. Optional timer pointers are null. Use a fresh process per job untilguard/finite validated. Graph repetitions must remain ordered on one stream, especially split4.

`buffers.check` covers full typed allocation initializedzero; untouchedpadding therefore passes finiteness and is **not** evidence of coverage. Record bytes written/nonzero separately where useful. Failure or unknown is not zero latency. `schedule_row` maps directly to the sourceCSV; `id`,symbol,geometry,grid,block identify every job for merging.

## Structures

|struct/userbytes|fields|
|---|---|
|VitFfwd48|ptr0input,8external,16output,24weights; i32 32H,36W,40P|
|VitConv80|ptr0input,8residual,16externalin,24tileout,32externalout,40weights; i32 48H,52W,56P; ptr64poolout; i32 72poolH,76poolW|
|Attn40|ptr0input,8output,16weights; i32 24H,28W,32shiftX,36shiftY|
|Expand32|ptr0input,8output,16weights,24timer|
|Conv1d80|ptr0input,8skip,16output,24weights; i32 32K,36matrixBytes,40splitparts; ptr48timer,56scratch; i32 64T; ptr72flags|
|Reg1dQkv72|ptr0input,8Q,16K,24V,32weights; i3240T; ptr48timer,56scratch,64flags|
|Reg1dAttn48|ptr0Q,8K,16V,24out; i3232Tpad,36Tvalid; ptr40timer|
|Repack48|ptr0input,8output; i32 16H,20W,24Tpad,28direction,32registerMode,36contentW,40contentH|
|Head24|ptr0input,8output,16weights|
|DecUp48|ptr0input,8skip,16output,24weights; i32 32ceil(sourceH/4),36destW/4,40destH/4,44destW/4|

Byte offsets are host-derived. Key ranges:043005–043038FFWD;043a54–043ae8 and043d69–043e14conv;043cab–043cdeattn;039135–039151expand;039306–039356 plus039d78–039da0contract;03a62d–03a6f7projection;03a17d–03a1c9QKV;03a550–03a578attention;038dfe–038e46 and03a992–03a9e6repack;038b6c–038b74head;03aeab–03aee7decup.

Correction to oldFFWD header: its nameswidth/height were reversed. Host042f8a/042f8d prove heightthenwidth. Old normal-variant timing did not use those dimensions; external variant does.

## Payload allocations

C512 internalinput/output=8192*P bytes,4×4token512-channel FP8 tile layout. FFWD weights524288B FP8. External raster buffer W*H*512 bytes. Convweights262144FP8 plus512half residual scales (D0074loads tails,D0190half multiply). Pooloutput8192*headTileCount bytes. Attentionweights3*512²FP8 +16*64²half bias +16floatnormscale (EAB70/EC140). All feature arrays stay byte storage.

ViT packedfeaturesT*1024B,expandedT*4096B,threeQKV arrays eachT*1024B. ConvweightsK*1024FP8 +1024half residual scales. QKVweights128-bytef32normscale prefix +3MiB FP8 matrix; matrixfirstoffset0x80 at101574,scalarload1025B0. Expandweights4MiB FP8. Headweights512*1024FP8,headoutput16384*Qbytes. Decupweights1024*512FP8 +512half scales,output8192*Pbytes (C05DCtail load).

Split4 scratch=3*T*8192B andflags80*(T/64)B,matching host03df5b..03e030. ISA F2E98 atomically increments itscounter, F2EF4 lastparticipant clearscountertozero; hence zero-init once and strictly sequential launches are valid. Reinitialize after any failed/cancelled launch. Do not run same splitflags concurrently.

Defaulttokens confirmed independently:object378/37c gets headW/headH at03db14/1b,370productat03dbcf,374ceil64at03dbee. Defaultnot`content` means448/640 validtokens, sameaspaddedT. Never substituteNVIDIA's540 validtokens intoDaniel640 here.

## Review status

ABI/metadata/host structure audited offline; jobs not GPU validated by this agent. Parent executes individualsmoke/guard/finite then graph timing. Any boundaryallocation/layout failure is handled as a failed row, not inferred timing. Whole-network sums are synthetic workload sums, not actual frame measurements.

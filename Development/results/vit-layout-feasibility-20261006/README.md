# Layout audit: actual M tile and one alternate bundle

Correction: nr_at16 is tilebase only. Actual M vit_attn.comp55–58 nr_at=tilebase+(token%16)*16+channel%16: token-major inside16×16tile. Samechannel eighttokens still stride16, so originalproducer cannot directly two8Bstore into actualMlayout. PALVTR belongs to that layout, not a column-major producer-friendly layout.

Historical exactscope: 9/23 experiments/vit-register-attention/prepare.py28–39 directly changespart2producer to[channel][token] andconsumer8Breads, noextra pass; Q/Kunchanged. r2README reports1080−.030/−.025/−.032ms,900−.012/−.021/−.023 mostlyoverlap/notaccepted. 9/26 vit-attn-c32-input/cand_deep.inc47–65 repeatsVonlyproducerdirecttwo8B withQ/Kunchanged/null. These already testedproducerdirectV; cannot relabelasextra-passnegative.

Only one distinct possiblebundle retained for future decision: threeplanes transposed16×16tiles, preserving3planeoffsets andoriginalnumericbytes. Address B(p,t,c)=p*N*1024+floor(t/16)*16384+floor(c/16)*256+(c%16)*16+t%16. This differsfromactualMlayout. Currentbin_w5f8 producer hip/vit_stream.inc197–232 owns t=first+gr8+e,c=row+j16+rc. Eightbytes perj becomecontiguous aligned8B withoutcrosslaneDS;512byte symbolicbijectionpassed. N640full16tiles avoidsnewtail.

Consumeronly640 keepsold WMMA operands: Q/Kdesired(token=rc,channel=j16+gr8+e) need2TRloads on physicalrowschannel/columnstoken (readrow=(lane/8)*4+(lane&3),readcol=(lane&4)?8:0). Vdesired(token=gr8+e,channel=j16+rc) isdirect2×8B. Thus trade: producer16b8→2b64 onallthreeparts; Q/K2b64→2TR each, V16u8→2b64. NoDSgatherneededbutTRlatency/addressdependency is real. No bandwith/ms claim. HWbytegold would be new onQ/Ktranspose andoriginalnumbers, priorAoSTR-Vgolddoesnotproveit. OldAoS16DSpackingAPPnegative649f remains.

No implementation orGPU. This is a newthreeplanephysicalrepresentation contract, not revivalofsameVonlyroute; whetherworthbuildingrequiresrootdecision andcanonical resource/ISA costgate. Mo-side score-only experiment remains the next causal evidence.

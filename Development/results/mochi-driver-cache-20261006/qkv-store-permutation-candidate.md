# Only final FP8 QKV store permutation, CPU proposal

Actualproductionvit-stream.hsaco SHAa085694b8679aee18b169a5aa2d886b12d579809b9f2bbfd4e097d4cf692b986 matchesfresh60566 manifest. Activevit_stream_qkv_frag_bin_w5f8 emits16global_store_b8 perwave tile (first90318, following90538..9058c and907xx). Sourcevit_stream.inc197–232 stores quantizedbytes at(part*tokens+first+group*8+e)*1024+row+j*16+lane%16. Existingfragmentmath/normalization/rounding allstayunchanged.

Newrepresentation-onlycandidate: afterquantization transpose the16byte/lane outputfragment forvectorstores, retainingoriginalAoS tensorbytes. Targetlane l:token t=l%16,chhalf=l/16; forj=0,1 andpackedbytek=0..7, takebytefromsource lane(t/8)*16+chhalf*8+k, sourceelemente=t%8, samej. TargetAoSaddress=(part*tokens+first+t)*1024+row+j*16+chhalf*8. Bothj boundaries remainseparate16channeltiles, two8Bstores perlane. CPUenumeration32×2×8 verifies512unique(token,column) positions identicaltooriginal16×32tile; nobytechanges, nomath/producer-outputlayout changes.

Eachpacked8Bword requiresup to8crosslane bytegathers andpacking; actualcompiler may costmore than16scalarstores. Currentinput/weightmatrices/LDS/WMMA allunchanged; no bandwidthreductionclaim ormsestimate. Scopefirst640fullwave andfullquerytile; anypartialwave mustretainoldpath. Bytefragmenthardwaregold andactualcanonicalISA/resource checks neededbeforeperformance, notCPUemulation-as-hardwareproof.

ThisdiffersfromnegativeTRconsumerload andfrom9/23physicalVtranspose (which changesQKVtensorlayout andconsumer). ExistingmhQKVoperandtranspose isnotthispurefinal-storepermutation. No matchingisolatedstore-onlyexperimentfoundinREADMEledgersearch; iflocatedbeforeimplementation, preserve itsnegative ratherthanrename it. NoGPU orcandidateimplementation byreviewer.

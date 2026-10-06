# Three-plane transposed tile: CPU canonical gate

Only pairedtokens640representation experiment, notactualMo rowtile. Current16-query andallnumeric expressions retained; noQB32/halfscore/halfden/newexit math. producerbinw5f8 solefunc changespack alreadyquantizedsamebytes into2aligned8B writes; consumer640byteinbout Q/K useTR andVdirect8B. Geometryoutside640 usesoriginalpaths. Pairmustbeinstalled intoexperimentmodeldirectory togetherbeforeloading; noone-module reuse/hotmix/default integration.

47148 fourCOMGRrows exit0/lockreleased,emptyopts/gfx1201. Produceroldfulla085694b matchesstock; consumerold11a25 matchesstock. Newproducer876fca9c resource76VGPR/22SGPR/16KiBLDS/private0/spill0 identicalold; newconsumer38da9a34 64VGPR/18SGPR/0LDS/private/spill (old68/12). Only1of86producerfuncs and1of78consumerfuncs changes, otherbytes exact; allABIs unchanged. Nooccupancy/speedclaim. ActualISA includesfallbackscalarstores/loads; live640 path producer2b64/0bpermute,consumer4QKTRsites +2Vb64; noaddedDS.

512tilebytebijection andQ/K/Vlogicalfragment mappings proved in232f9c3f CPUmodel; hardwarefixturemustchecknewQ/KTRtypedbytes,producer output threeplanes andVdirect bytes. PriorAoSTR-Vunit doesnotproveit. Old9/23producerdirectVonlynegative/null and649fAoSbutterflyAPPnegative remain. NoGPU gold/performance run.

86251sameCOMGR primitivecompile/97615GPU singlegold exit0/release. Twofull3plane640fixtures rawallbits/nonNaN haveproducerinverse/oldCPUfragment/QKTR/Vdirectallbyte0. Alreadyquantizedbytes only; no claimcompleteQKVnormalization orwholeNNmathgold. ModulepairSHApreflightpassedbeforelaunch. Wrapper末linewrongoldQB32labelretainedasreceiptpitfall, actualCOLUMN_GOLD fields correct; CPUscripttextfixedwithoutrepeat.

59652 wholeNN firstgate FAIL exit1/release: OLD153ac matchescurrentA;NEWefb02457 differs. Bothselfrepeatfinite passed. Transportprimitive cannot establishactualquantizedproduceroutput equality. Noperformance. Keepcurrentfailure; CPUsource/typedmapping nohardblock, nextlocalization would needactualproducerinput/weights andinversequantizedoutputbeforeconsumer. No claim numericalcontract passed.

36118actualfirstproducer shadowdiagnostic exit0/release: input655360B andactualcacheweights3145856B D2Downed,768groups×160threads,n640. Oldshadow matchesoriginaloutputall1966080bytes; newinverse matchesoldallbytes,eachplane/head/tile0. OriginalwholeNN153ac unchanged. Firstproducerpassed; whole59652mismatch unresolved, nextconsumeractualdata check required. No performance.

72890actualfirstconsumer shadowexit0/release: inputmatches36118capture, oldshadow/originalbyte0,newshadow/oldbyte0,655360bytes. n640/1280groups/32threads/reusegateNULL; noweight,bias,skip,remaparguments. Firstisolatedproducer/consumerpaircorrect.

## Material active-module correction

59652wholefailure is mixedlayoutstagebug: host699 loadsFastTwin("vit-stream"),354–357 selects vit-stream-fast underFAST1. Actualstagedmodules-new/vit-stream-fast.hsaco remainedstockSHA877eaf122f827af6e00824582f5ca918b5d61499d4ad7c7cde7ab6e422516a57; onlynormal vit-stream.hsaco changedto876fca9c. Newconsumer38da wasloadedwitholdAoSproducer. This invalidatesclaim thatwhole59652testedpairedactivecandidate, butfailure/rawremainpreserved. a085normalproducer identity/resources are notactualFAST1baseline; primitive/isolatedshadowresults remainlocal contracts only. Mustgenerate actualvit-stream-fast recipeold/new andverifyoldwhole877e beforefixingstage, notrename876asfast. No furtherGPU/performance run.

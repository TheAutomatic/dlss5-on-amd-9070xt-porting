# Pooled register cache/dead scratch reuse: static STOP

Modeld4362d7d, onegeneratedvariant experiments/body22-down-regcache-20261006/prepare.py. LocalcanonicalLLVM23/-real-true16/MSABI/C++14/sameoldrowopts build30703 exit0, SHA9baaeec01845ef30e90cfff486e2b616ff45122a4f52265e82c75d89367d0213. Onlynewfusionexport intended; raw/normalpoolmathematics/80ABI/route untouched, cached8explicitu32/lane, extra8fixedgathers perqt, reusebarrier thenplane0 stores thenconsumerbarrier; oldscratchonlyreusedafterallfinalprojection reads.

ActualnewFn VGPR237/SGPR19/LDS32768/private192/RAspillcounts0/wave32. TargetLDSachieved butprivate scratch isstaticredline: **STOP**, noGPU/gold/performance, noopts sweep. LowerVGPR isnotgain whenpartofstate resides inprivate memory.

ActualISA contains15scratch_store_b32,7store_b128,1store_b64,40scratch_load_b32,1load_b128 sites. Optimizedfrontkernel has15i32 allocas inprivateaddrspace5 plusclass.anon.136=15genericptrclosure. Source8cachevariablescapturedbyreference togetherwith7otherlocals remainaddressable;15×4+15×8=180bytes (rounded192) consistentwithactualprivateallocation. No[8xi32] wordsarrayallocas survived; thus dynamicarray8wasnot theobservedretainedstate. ThisisIRprivateobject/closurestorage, notflaggedregisterallocatorspilling, explainingRAspill_count0. Exactpassresponsible isnotclaimed.

Source/manifest/notes/allocas/closure/scratchinstructionoffsets retained. Noautomaticlambda rewrite orsecondresourcevariant; staticSTOP belongs tothissingle implementation, notproofallregistercache approachesimpossible. No productionchange/install/ZIP/push.

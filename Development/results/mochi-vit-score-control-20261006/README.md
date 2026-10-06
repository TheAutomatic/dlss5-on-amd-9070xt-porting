# LockedM ViT score-only F32 control, CPU/device-create evidence

Purpose iscontrolledmathshortcutcost, notdeployment orslowingcompetitor todeclarematchinggoal. LockedM d1185d2 andoriginalpure7.885baseline stayauthoritative. HIP M32×halfscoreden combinednegative doesnotidentifycausalshortcutcost.

EffectiveQB2: NR_QT32/VWAVES1,VTRANS1,KPERM1,halfden64. ActiveVT_fullbranch alwaysf16vec2part/scalarden rounds; VPACKED_DEN0 doesnotmakeitF32. VTRANS0 changeslayout. NoexistingHIP-equivalentF32K16den switch; float64tree substitution wouldnotclaimHIPWMMAorder. Singlevariantchangesonlynr_vit_exp2: halfinput/FMA/clip→preciseF32multiplythenadd/clip/bittruncmap, retaininghalfden/QB2/QK/Vlayout/TR/AV/f16exit/padding. HIPactualstockMUL3db76000/ADD3fdac000 areseparate, so notFMA32claim. NewSPV NoContractiondecorations116/121.

Originalglslang-E→quad_quant_glsl NR_Q32_DIRECT1→Vulkan1.3 compile reproducedoldSPV8993390ab9316895daf19c3c9ba669b984301c4a1624e87901fbcbf2e46634b1 wholebyteexact. New1a6d2b5f46dfacba6ccf4568d9c92f5a0a5d9547e8f81f71f0bc728921fbacae. ActualoldSPVdirectory recursive65files/60SPVs (70oldassetmanifest isdifferentcount), overlayonlyg_vitattnchanges,64otherfiles/59SPVs+markerssameSHA. Nevermodifyoldassets.

34855 isolatedpipelinecreateonly exit0/released, exactoriginal3SSBO/push28/samedriver26.10.07.02LLPC. NewPAL114VGPR/30SGPR/LDS0/scratch0/wave32 sameoldmappedcache14resources. ActualISA halfFMA64→0, independentfloatmul/addnoconstrictedFMA; WMMA64/TR16/packedhalfdenadd96 unchangedcounts. Changesalsoincludeclip/bitpack/conversions/scheduling, notallotherISAbyteidentity. Detailedopcodecountsretained, no staticinstructionlength→ms inference.

CPU run_diagready originalexe onlySPVswap, warm80/repeats2/chunk1/style1seed0/sameinput/model/plan andseparateownpcfiles. Originalexeonlywritesfinalimage; twoindependentprocesses per side establishfinaloutputcrossprocessrepeat, notfirstwarmread/perframegold. NextgatefiniteRGBA/alpha andvalidRGBerrorrelativeoldM (PSNR/MAE/max), geometry1088/tokens640/paddingflagsunchanged. Noexpectedcrossmathrawsame orproductionPSNRthreshold. Acceptmathdiagonlyif deterministic/finite anderrorreportedtransparently; newunexpectednonfinite/repeatfail stops. ActualcompleteNN andperformance notyetexecuted. No69SPVfiction, noprimarybaseline substitution.

## Actual complete-network numerical and timing counterfactual

56520 fourindependentprocesses(old2/new2) warm80/repeats2/chunk1 exit0/released, ownfinalcrossprocessrepeatbit0, allRGBAfinite/alpha1. OldSHA624d9d1a…samefreshold; newe2a4daea…fixed. RelativeoldvalidRGB peak1PSNR52.7257152203dB/MAE.001708935267/maxabs.03102321923,6220751differentfloatvalues. Theseare newmatherrorsrelativeMold, notoriginalNV/productionacceptance.

67182 singleold/new/new/old ABBA warm80/repeats160/chunk1 sameoriginalexe/input/model/plan/nonVTassets andsameprovider, noRDTS/clockmodification. Variantfinalraw eachSHA matches its own numericalreference; nofirstwarmreadback interface andno p99 output, so neitherfake first-read gate norfabricatedp99. GPUmeans7.8325125/7.85179375/7.85716875/7.857725ms; host7.97783125/7.992425/7.99285/7.99764375. New−oldGPU+.0093625ms/host+.0049ms,oldcontrolGPUdrift+.0252125/host+.0198125ms. Aggregate totals printed3decimal precision anddivided160, notperframe distributions.

Effectsmallerthancontrol drift: onecontrolledrun doesnotrobustlyestablish9usshortcutcost orsupporthalfscore aloneexplaining1.046ms. **STOP** thisscore-onlycounterfactual: norepeats/formal/countercapture/productionchanges. It doesnotaddresshalf64den shortcut anddoesnotclaimHIPF32K16den equivalent. Oldcompetitor7.885259/freshgap1.04628575 remainoriginalunmodifiedtargets; deliberatelynewmathM isneveradoptedascompetitorbaseline orusedtosubtractgoal.

Physicallayout clarification: nr_at16 simplifiedtilebase appliesalignedtoken/channel; fullnr_at includeswithin16tile token-majorrowstride16. ColumnMajorcooploadreinterpretation isnotphysicalcolumn-majorV. Thisdoesnotaffectscore-onlysource/SPVbytecontrol, andpastTRbytegold/negativeledger remainunchanged.

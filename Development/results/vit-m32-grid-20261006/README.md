# QB32 empty-grid control: CPU ready

Same canonical8d5 halfmath module; explicit labhost grid selector changes onlydeep_fast/vit_attention_fused_640_bytein_bout withcount640*512 andthreads32 from1280groups to640. Defaultselector0 andallotherkernels unchanged. This corrects launch organization in the isolated experiment, not oldda549negative invalidation.

Generatedkernel first=(bid/32)*32/head=bid%32. Livebid0..639 covers640queries×32heads exactlyonce usingtwo16-queryblocks. Droppedbid640..1279 returnsuniformly atfirst>=640 beforeinputs/outputs; noK/V/score/den/AV changes. Twooriginal ABI-independent hostbuilds local10574/79669 exit0.

Goldscript prepared foroldgrid/newgrid each2frames, same8d5 module, finite/repeat andexact933e2a5f oldNEWmathoutputSHA. Logs actualtargetcall grid. Scope is fixed known640module; no production route/fallback claims. GPU NOT run/authorized yet. Nextperfifauthorized comparesonlynewmathgrid1280 vs640, neveroldA16math.

$ErrorActionPreference='Stop';$root=$PSScriptRoot
foreach($a in 'gfx1200','gfx1201'){New-Item -ItemType Directory -Force "$root\HIP\$a"|Out-Null;foreach($n in 'multi-pass-predict','multi-pass-skin'){$source=if($n -eq 'multi-pass-predict'){'multi_pass_predict.hip'}else{'multi_pass_skin.hip'};& 'D:\DLSSNR-Lab\multi-pass-predict-20261004\rtc_compile.exe' "$root\HIP\$a\$n.hsaco" "$root\$source" comgr $a;if($LASTEXITCODE){throw 'compile failed'}}}
'BUILD_SMALL_DONE'

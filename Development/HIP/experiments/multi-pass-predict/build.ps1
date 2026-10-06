$ErrorActionPreference='Stop';$root=$PSScriptRoot
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
foreach($a in 'gfx1200','gfx1201'){New-Item -ItemType Directory -Force "$root\HIP\$a"|Out-Null;& "$root\rtc_compile.exe" "$root\HIP\$a\multi-pass-predict.hsaco" "$root\multi_pass_predict.hip" comgr $a;if($LASTEXITCODE){throw 'compile failed'}}
'BUILD_DONE'

$ErrorActionPreference='Stop';$root=$PSScriptRoot
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
foreach($a in 'gfx1200','gfx1201'){New-Item -ItemType Directory -Force "$root\HIP\$a"|Out-Null;Copy-Item "D:\DLSSNR-Lab\current-main-20261003\HIP\$a\*.hsaco" "$root\HIP\$a" -Force;Copy-Item "D:\DLSSNR-Lab\multi-pass-predict-20261004\HIP\$a\multi-pass-predict.hsaco" "$root\HIP\$a" -Force;& 'D:\DLSSNR-Lab\multi-pass-predict-20261004\rtc_compile.exe' "$root\HIP\$a\multi-pass-skin.hsaco" "$root\multi_pass_skin.hip" comgr $a;if($LASTEXITCODE){throw 'compile failed'}}
'BUILD_DONE'

$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\fusion-round3'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile'}){throw 'GPU busy'}
foreach($module in 'c64-wave2','c32-wave1'){
 & "$r\hip-production\build-modules.ps1" -SourceDir "$r\hip-production" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\production" -Only $module
 if($LASTEXITCODE){throw 'compile'}
 & "$r\hip-production\build-modules.ps1" -SourceDir "$r\hip-production" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\default-off" -Only $module -ExtraDefines @('W2_UP_FUSED 0','CW_UP_FUSED 0')
 if($LASTEXITCODE){throw 'control compile'}
}
foreach($set in 'C','U2'){New-Item -ItemType Directory -Force "$r\flat-$set"|Out-Null;Copy-Item "$r\flat-A\*.hsaco" "$r\flat-$set" -Force}
Copy-Item "$r\production\gfx1201\*.hsaco" "$r\flat-C" -Force
Copy-Item "$r\production\gfx1201\c64-wave2.hsaco" "$r\flat-U2" -Force

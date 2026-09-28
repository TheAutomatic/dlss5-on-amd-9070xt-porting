$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c512-fusion'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile'}){throw 'GPU busy'}
foreach($module in 'c512-m32-mh','c64-wave2'){
 & "$r\hip-production\build-modules.ps1" -SourceDir "$r\hip-production" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\production" -Only $module
 if($LASTEXITCODE){throw 'production compile'}
 & "$r\hip-production\build-modules.ps1" -SourceDir "$r\hip-production" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\default-off" -Only $module -ExtraDefines @('C512_FUSED_QKV_ATTN 0','W2_FFN_QT_SMALL_MASK 0')
 if($LASTEXITCODE){throw 'default off compile'}
}
New-Item -ItemType Directory -Force "$r\flat-C"|Out-Null
Copy-Item "$r\flat-A\*.hsaco" "$r\flat-C" -Force
Copy-Item "$r\production\gfx1201\*.hsaco" "$r\flat-C" -Force

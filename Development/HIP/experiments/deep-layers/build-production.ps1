$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\deep-layers'
function Idle {if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^runtime-smoke|^rtc_compile|^microbench'}){throw 'GPU busy'}}
foreach($arch in 'gfx1200','gfx1201'){
 Idle
 & "$r\hip-production\build-modules.ps1" -SourceDir "$r\hip-production" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\production\$arch" -Only c512-m32-mh -Targets $arch
 if($LASTEXITCODE){throw 'production compile'}
 Idle
 & "$r\hip-production\build-modules.ps1" -SourceDir "$r\hip-production" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\default-off\$arch" -Only c512-m32-mh -Targets $arch -ExtraDefines @('C512_COMPACT_QKV_ATTN 0')
 if($LASTEXITCODE){throw 'default off compile'}
}
New-Item -ItemType Directory -Force "$r\flat-P"|Out-Null
Copy-Item "$r\flat-A\*.hsaco" "$r\flat-P" -Force
Copy-Item "$r\production\gfx1201\c512-m32-mh.hsaco" "$r\flat-P" -Force

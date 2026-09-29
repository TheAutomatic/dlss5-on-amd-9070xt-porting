$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\kernel-map'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^recorder|^jobbench|^microbench|^rtc_compile'}){throw 'GPU busy'}
& "$r\hip-H\build-modules.ps1" -SourceDir "$r\hip-H" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-H-gfx1201" -Only multihead-fast-padded-wave-packed -Targets gfx1201 -ExtraDefines @('C512_HEAD_GROUP 1')
if($LASTEXITCODE){throw 'compile'}
New-Item -ItemType Directory -Force "$r\flat-H","$r\flat-C"|Out-Null
Copy-Item "$r\flat-A\*.hsaco" "$r\flat-H" -Force
Copy-Item "$r\build-H-gfx1201\multihead-fast-padded-wave-packed.hsaco" "$r\flat-H" -Force
Copy-Item "$r\flat-H\*.hsaco" "$r\flat-C" -Force
Copy-Item "$r\build-V-gfx1201\deep_fast-packed.hsaco" "$r\flat-C" -Force

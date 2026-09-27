$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\tier900'
Copy-Item 'D:\DLSSNR-Lab\hip-backend\mh-round1\modules-A' "$r\modules-A" -Recurse -Force
Copy-Item "$r\modules-A" "$r\modules-P" -Recurse -Force
Copy-Item 'D:\DLSSNR-Lab\hip-backend\mh-round1\benchmark.exe' "$r\benchmark.exe" -Force
& "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-P" -Only c512-m32-deep -ExtraDefines @('C512_ZERO_PAD_900 1')
if($LASTEXITCODE){throw 'compile'}
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$r\build-P\$a\c512-m32-deep.hsaco" "$r\modules-P\$a\" -Force}

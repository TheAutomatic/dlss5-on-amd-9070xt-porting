$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mochizuki-022'
& "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-H" -Only c512-m32-deep -ExtraDefines @('C512_WG4 1')
if($LASTEXITCODE){throw 'WG4 compile'}
Copy-Item "$r\modules-A" "$r\modules-H" -Recurse -Force
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$r\build-H\$a\c512-m32-deep.hsaco" "$r\modules-H\$a\" -Force}

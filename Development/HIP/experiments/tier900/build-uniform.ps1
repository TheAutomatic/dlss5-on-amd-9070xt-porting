$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\tier900'
Copy-Item "$r\modules-A" "$r\modules-U" -Recurse -Force
& "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-U" -Only c512-m32-deep -ExtraDefines @('C512_ZERO_PAD_900 2')
if($LASTEXITCODE){throw 'compile'}
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$r\build-U\$a\c512-m32-deep.hsaco" "$r\modules-U\$a\" -Force}

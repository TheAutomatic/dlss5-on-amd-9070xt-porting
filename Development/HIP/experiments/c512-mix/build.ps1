$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c512-mix'
Copy-Item 'D:\DLSSNR-Lab\hip-backend\vit-bytestream\modules-A' "$r\modules-A" -Recurse
Copy-Item "$r\modules-A" "$r\modules-H" -Recurse
& "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-H" -Only c512-half
if($LASTEXITCODE){throw 'compile'}
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$r\build-H\$a\c512-half.hsaco" "$r\modules-H\$a\"}

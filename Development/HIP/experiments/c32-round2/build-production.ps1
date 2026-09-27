$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c32-round2'
& "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-production" -Only c32-wave1
if($LASTEXITCODE){throw 'production build failed'}

$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mh-round1'
& "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\production" -Only c64-wave2
if($LASTEXITCODE){throw 'production compile'}

$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\vit-bytestream'
& "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\production" -Only vit-stream
if($LASTEXITCODE){throw 'production compile'}

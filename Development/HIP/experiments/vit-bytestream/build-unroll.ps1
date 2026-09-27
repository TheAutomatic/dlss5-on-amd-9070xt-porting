$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\vit-bytestream'
& "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-U" -Only vit-stream -ExtraDefines @('HIP_VIT_STREAM_QKV_UNROLL 2')
if($LASTEXITCODE){throw 'unroll build'}
Copy-Item "$r\modules-V3" "$r\modules-V4" -Recurse
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$r\build-U\$a\vit-stream.hsaco" "$r\modules-V4\$a\" -Force}

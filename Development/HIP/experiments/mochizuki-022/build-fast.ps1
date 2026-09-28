$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mochizuki-022'
& "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-F" -Only vit-stream -ExtraDefines @('HIP_TILE_CHAIN 1','HIP_TILE_CHAIN_RELAXED 1')
if($LASTEXITCODE){throw 'TC relaxed compile'}
Copy-Item "$r\modules-A" "$r\modules-F" -Recurse -Force
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$r\build-F\$a\vit-stream.hsaco" "$r\modules-F\$a\" -Force}

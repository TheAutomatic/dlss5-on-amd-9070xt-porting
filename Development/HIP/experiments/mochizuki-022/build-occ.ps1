$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mochizuki-022'
foreach($m in 'c512-m32-deep','vit-stream'){
 & "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-O" -Only $m -ExtraDefines @('C512_MIX_OCC_LDS 4096','VIT_CONTRACT_OCC_LDS 4096')
 if($LASTEXITCODE){throw "Occupancy compile $m"}
}
Copy-Item "$r\modules-A" "$r\modules-O" -Recurse -Force
foreach($a in 'gfx1200','gfx1201'){foreach($m in 'c512-m32-deep','vit-stream'){Copy-Item "$r\build-O\$a\$m.hsaco" "$r\modules-O\$a\" -Force}}

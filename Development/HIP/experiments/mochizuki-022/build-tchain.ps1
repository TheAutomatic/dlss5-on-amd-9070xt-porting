$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mochizuki-022'
foreach($m in 'deep_fast-packed','c512-m32-mh','vit-stream'){
 & "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-T" -Only $m -ExtraDefines @('HIP_TILE_CHAIN 1')
 if($LASTEXITCODE){throw "TC compile $m"}
}
foreach($set in 'S','V','T'){
 if(!(Test-Path "$r\modules-$set")){Copy-Item "$r\modules-A" "$r\modules-$set" -Recurse}
 $mods=if($set -eq 'S'){@('deep_fast-packed','c512-m32-mh')}elseif($set -eq 'V'){@('vit-stream')}else{@('deep_fast-packed','c512-m32-mh','vit-stream')}
 foreach($a in 'gfx1200','gfx1201'){foreach($m in $mods){Copy-Item "$r\build-T\$a\$m.hsaco" "$r\modules-$set\$a\" -Force}}
}

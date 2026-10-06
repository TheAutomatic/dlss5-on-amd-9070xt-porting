$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mochizuki-022'
foreach($m in 'c512-m32-deep','c512-m32-mh'){
 & "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-G" -Only $m -ExtraDefines @('C512_WEIGHT_MAJOR 1')
 if($LASTEXITCODE){throw "Group major compile $m"}
}
Copy-Item "$r\modules-A" "$r\modules-G" -Recurse -Force
foreach($a in 'gfx1200','gfx1201'){foreach($m in 'c512-m32-deep','c512-m32-mh'){Copy-Item "$r\build-G\$a\$m.hsaco" "$r\modules-G\$a\" -Force}}

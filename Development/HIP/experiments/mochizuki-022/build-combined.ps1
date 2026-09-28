$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mochizuki-022'
& "$r\build.ps1" -Sets C
if($LASTEXITCODE){throw 'Combined compile'}
foreach($a in 'gfx1200','gfx1201'){foreach($m in 'c512-m32-deep','vit-stream'){Copy-Item "$r\modules-O\$a\$m.hsaco" "$r\modules-C\$a\" -Force}}
'COMBINED_READY'

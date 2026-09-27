$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\vit-c512-aco'
New-Item -ItemType Directory -Force "$r\modules-A","$r\modules-V"|Out-Null
foreach($a in 'gfx1200','gfx1201'){
 Copy-Item "D:\DLSSNR-Lab\hip-backend\c32-round3\modules-A\$a" "$r\modules-A\$a" -Recurse -Force
 Copy-Item "$r\modules-A\$a" "$r\modules-V\$a" -Recurse -Force
}
Copy-Item 'D:\DLSSNR-Lab\hip-backend\c32-round3\benchmark.exe' "$r\benchmark.exe"
foreach($m in 'deep_fast-packed','vit-wide-deep','c512-m32-deep','c512-m32-mh'){
 & "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-A" -Only $m
 if($LASTEXITCODE){throw "baseline $m"}
}
foreach($m in 'deep_fast-packed','vit-wide-deep'){
 & "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-V" -Only $m -ExtraDefines @('HIP_VIT_AV_BYTE 1')
 if($LASTEXITCODE){throw "prototype $m"}
 foreach($a in 'gfx1200','gfx1201'){Copy-Item "$r\build-V\$a\$m.hsaco" "$r\modules-V\$a\" -Force}
}

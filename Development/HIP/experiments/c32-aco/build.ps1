param([string[]]$Sets=@('Z','B','C','D'))
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c32-aco'
$defines=@{Z=@('CW_FMED3_CLAMP 0','CW_DIRECT_OUT 0','CW_RTZ_PAIR 0');B=@('CW_FMED3_CLAMP 1','CW_DIRECT_OUT 0','CW_RTZ_PAIR 0');C=@('CW_FMED3_CLAMP 0','CW_DIRECT_OUT 1','CW_RTZ_PAIR 0');D=@('CW_FMED3_CLAMP 0','CW_DIRECT_OUT 0','CW_RTZ_PAIR 1');E=@('CW_FMED3_CLAMP 0','CW_DIRECT_OUT 1','CW_RTZ_PAIR 1')}
foreach($set in $Sets){
 & "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-$set" -Only c32-wave1 -ExtraDefines $defines[$set]
 if($LASTEXITCODE){throw "compile failed $set"}
 foreach($a in 'gfx1200','gfx1201'){
  New-Item -ItemType Directory -Force "$r\modules-$set\$a"|Out-Null
  Copy-Item "$r\modules-A\$a\*.hsaco" "$r\modules-$set\$a\" -Force
  Copy-Item "$r\build-$set\$a\c32-wave1.hsaco" "$r\modules-$set\$a\c32-wave1.hsaco" -Force
 }
}

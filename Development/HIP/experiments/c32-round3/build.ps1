param([string[]]$Sets=@('P','Q','F'))
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c32-round3'
$defs=@{
 P=@('CW_POST_HEAD_VEC 1','CW_POST_FULL_TILE 0','CW_FINISH_FULL_TILE 0')
 Q=@('CW_POST_HEAD_VEC 0','CW_POST_FULL_TILE 1','CW_FINISH_FULL_TILE 0')
 F=@('CW_POST_HEAD_VEC 0','CW_POST_FULL_TILE 0','CW_FINISH_FULL_TILE 1')
 E=@('CW_POST_HEAD_VEC 1','CW_POST_FULL_TILE 1','CW_FINISH_FULL_TILE 1')
}
foreach($set in $Sets){
 & "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-$set" -Only c32-wave1 -ExtraDefines $defs[$set]
 if($LASTEXITCODE){throw "build failed $set"}
 foreach($a in 'gfx1200','gfx1201'){
  New-Item -ItemType Directory -Force "$r\modules-$set\$a"|Out-Null
  Copy-Item "$r\modules-A\$a\*.hsaco" "$r\modules-$set\$a\" -Force
  Copy-Item "$r\build-$set\$a\c32-wave1.hsaco" "$r\modules-$set\$a\" -Force
 }
}

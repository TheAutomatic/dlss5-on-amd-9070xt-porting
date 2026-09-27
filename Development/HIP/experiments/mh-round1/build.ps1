param([string[]]$Sets=@('B','R','T'))
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mh-round1'
$defs=@{
 B=@('W2_BYTE_INPUT_LOADS 1','W2_RTZ_PAIR 0','W2_DIRECT_COORDS 0','W2_FULL_WINDOW 0','W2_DIRECT_FEATURE 0')
 R=@('W2_BYTE_INPUT_LOADS 0','W2_RTZ_PAIR 1','W2_DIRECT_COORDS 0','W2_FULL_WINDOW 0','W2_DIRECT_FEATURE 0')
 T=@('W2_BYTE_INPUT_LOADS 0','W2_RTZ_PAIR 0','W2_DIRECT_COORDS 0','W2_FULL_WINDOW 1','W2_DIRECT_FEATURE 0')
 C=@('W2_BYTE_INPUT_LOADS 0','W2_RTZ_PAIR 0','W2_DIRECT_COORDS 1','W2_FULL_WINDOW 0','W2_DIRECT_FEATURE 0')
 D=@('W2_BYTE_INPUT_LOADS 0','W2_RTZ_PAIR 0','W2_DIRECT_COORDS 0','W2_FULL_WINDOW 0','W2_DIRECT_FEATURE 1')
 E=@('W2_BYTE_INPUT_LOADS 1','W2_RTZ_PAIR 1','W2_DIRECT_COORDS 1','W2_FULL_WINDOW 0','W2_DIRECT_FEATURE 0')
 Z=@('W2_BYTE_INPUT_LOADS 0','W2_RTZ_PAIR 0','W2_DIRECT_COORDS 0','W2_FULL_WINDOW 0','W2_DIRECT_FEATURE 0')
}
foreach($set in $Sets){
 & "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-$set" -Only c64-wave2 -ExtraDefines $defs[$set]
 if($LASTEXITCODE){throw "build $set"}
 Copy-Item "$r\modules-A" "$r\modules-$set" -Recurse -Force
 foreach($a in 'gfx1200','gfx1201'){Copy-Item "$r\build-$set\$a\c64-wave2.hsaco" "$r\modules-$set\$a\" -Force}
}

param([string[]]$Sets=@('I','P','Z'))
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mochizuki-022'
$defs=@{I=@('CW_INPUT_HALF 3');P=@('CW_PREFIX_HALF_SOURCE 1');C=@('CW_INPUT_HALF 3','CW_PREFIX_HALF_SOURCE 1');Z=@()}
foreach($set in $Sets){
 & "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-$set" -Only c32-wave1 -ExtraDefines $defs[$set]
 if($LASTEXITCODE){throw "Compile $set"}
 if(!(Test-Path "$r\modules-$set")){Copy-Item "$r\modules-A" "$r\modules-$set" -Recurse}
 foreach($a in 'gfx1200','gfx1201'){Copy-Item "$r\build-$set\$a\c32-wave1.hsaco" "$r\modules-$set\$a\" -Force}
}

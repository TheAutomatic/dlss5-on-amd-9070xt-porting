param([string[]]$Sets=@('R','Q'))
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c512-round1'
$defs=@{L=@('C512_QKV_LDS_ALIAS 1');N=@('C512_MIX_N32 1');R=@('C512_MIX_PAIR 1');Q=@('C512_QKV_DIRECT 1');E=@('C512_MIX_PAIR 1','C512_QKV_DIRECT 1');Z=@()}
foreach($set in $Sets){
 $mods=if($set -in @('R','N')){@('c512-m32-deep')}elseif($set -in @('Q','L')){@('c512-m32-mh')}else{@('c512-m32-deep','c512-m32-mh')}
 foreach($m in $mods){& "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-$set" -Only $m -ExtraDefines $defs[$set];if($LASTEXITCODE){throw 'compile'}}
 if(!(Test-Path "$r\modules-$set")){Copy-Item "$r\modules-A" "$r\modules-$set" -Recurse}
 foreach($a in 'gfx1200','gfx1201'){foreach($m in $mods){Copy-Item "$r\build-$set\$a\$m.hsaco" "$r\modules-$set\$a\" -Force}}
}

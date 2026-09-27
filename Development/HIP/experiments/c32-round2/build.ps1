param([string[]]$Sets=@('Z','CN','M','C','D'))
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c32-round2'
$defs=@{
 Z=@('CW_PACK_MODE_MASK 0','CW_PACK_CENSUS 0','CW_PREFIX_DIRECT_OUT 0','CW_PREFIX_FULL_TILE 0')
 CN=@('CW_PACK_CENSUS 1','CW_PACK_MODE_MASK 0','CW_PREFIX_DIRECT_OUT 0','CW_PREFIX_FULL_TILE 0')
 C=@('CW_PACK_MODE_MASK 0','CW_PACK_CENSUS 0','CW_PREFIX_DIRECT_OUT 1','CW_PREFIX_FULL_TILE 0')
 D=@('CW_PACK_MODE_MASK 0','CW_PACK_CENSUS 0','CW_PREFIX_DIRECT_OUT 0','CW_PREFIX_FULL_TILE 1')
 M=@('CW_PACK_MODE_MASK 127','CW_PACK_CENSUS 0','CW_PREFIX_DIRECT_OUT 0','CW_PREFIX_FULL_TILE 0')
 E=@('CW_PACK_MODE_MASK 127','CW_PACK_CENSUS 0','CW_PREFIX_DIRECT_OUT 1','CW_PREFIX_FULL_TILE 1')
}
foreach($set in $Sets){
 if(!$defs.ContainsKey($set)){throw "Unknown/rejected candidate $set (B was the hoisted intrinsic prototype)"}
 & "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-$set" -Only c32-wave1 -ExtraDefines $defs[$set]
 if($LASTEXITCODE){throw "build failed $set"}
 foreach($a in 'gfx1200','gfx1201'){
  New-Item -ItemType Directory -Force "$r\modules-$set\$a"|Out-Null
  Copy-Item "$r\modules-A\$a\*.hsaco" "$r\modules-$set\$a\" -Force
  Copy-Item "$r\build-$set\$a\c32-wave1.hsaco" "$r\modules-$set\$a\" -Force
 }
}

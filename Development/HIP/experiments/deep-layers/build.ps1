param([string]$Arch='gfx1201',[string[]]$Sets=@('R','V','C'))
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\deep-layers'
foreach($set in $Sets){
 if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^runtime-smoke|^rtc_compile|^microbench'}){throw 'GPU busy'}
 $d="$r\build-$set-$Arch";New-Item -ItemType Directory -Force $d|Out-Null
 $module=if($set -eq 'C'){'c512-m32-mh'}else{'deep_fast-packed'}
 $def=switch($set){'R'{'C512_REGISTER_FFN 1'}'V'{'VIT_EXPAND_CONSUMER_FLOAT 1'}'C'{'C512_COMPACT_QKV_ATTN 1'}}
 & "$r\hip-$set\build-modules.ps1" -SourceDir "$r\hip-$set" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir $d -Only $module -Targets $Arch -ExtraDefines @($def)
 if($LASTEXITCODE){throw 'compile'}
 if($Arch -eq 'gfx1201'){
  New-Item -ItemType Directory -Force "$r\flat-$set"|Out-Null;Copy-Item "$r\flat-A\*.hsaco" "$r\flat-$set" -Force;Copy-Item "$d\$module.hsaco" "$r\flat-$set" -Force
  if($set -eq 'R'){New-Item -ItemType Directory -Force "$r\flat-RF"|Out-Null;Copy-Item "$r\flat-R\*.hsaco" "$r\flat-RF" -Force}
 }
}

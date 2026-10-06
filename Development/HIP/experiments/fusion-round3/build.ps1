param([string]$Arch='gfx1201',[string[]]$Sets=@('P','U','T'))
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\fusion-round3'
foreach($set in $Sets){
 if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile'}){throw 'GPU busy'}
 $d="$r\build-$set-$Arch";New-Item -ItemType Directory -Force $d|Out-Null
 if($set -eq 'P'){$module='vit-stream';& 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' "$d\$module.hsaco" "$r\vit-stream.generated.hip" comgr $Arch}
 else{$module=if($set -eq 'U'){'c64-wave2'}else{'c32-wave1'};$def=if($set -eq 'U'){'W2_UP_FUSED 1'}else{'CW_UP_FUSED 1'}
  & "$r\hip-test\build-modules.ps1" -SourceDir "$r\hip-test" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir $d -Only $module -Targets $Arch -ExtraDefines $def
 }
 if($LASTEXITCODE){throw 'compile'}
 if($Arch -eq 'gfx1201'){
  New-Item -ItemType Directory -Force "$r\flat-$set"|Out-Null;Copy-Item "$r\flat-A\*.hsaco" "$r\flat-$set" -Force;Copy-Item "$d\$module.hsaco" "$r\flat-$set" -Force
  if($set -eq 'P'){New-Item -ItemType Directory -Force "$r\flat-G"|Out-Null;Copy-Item "$r\flat-P\*.hsaco" "$r\flat-G" -Force}
 }
}

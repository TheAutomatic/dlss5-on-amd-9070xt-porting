param([string]$Arch='gfx1201')
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\daniel-kernels'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench'}){throw 'GPU busy'}
foreach($item in @(@('Z32',0),@('Q',1),@('R',2),@('C',3))){
 $set=$item[0];$mask=$item[1]
 & "$r\hip-test\build-modules.ps1" -SourceDir "$r\hip-test" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-$set-$Arch" -Only c32-wave1 -Targets $Arch -ExtraDefines @("CW_WEIGHT_CACHE $mask")
 if($LASTEXITCODE){throw 'compile'}
 if($Arch -eq 'gfx1201'){
  New-Item -ItemType Directory -Force "$r\flat-$set"|Out-Null
  Copy-Item "$r\flat-A\*.hsaco" "$r\flat-$set" -Force
  Copy-Item "$r\build-$set-$Arch\c32-wave1.hsaco" "$r\flat-$set\c32-wave1.hsaco" -Force
 }
}

param([string]$Arch='gfx1201')
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\daniel-kernels'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench'}){throw 'GPU busy'}
foreach($set in 'Z','P'){
 $def=if($set -eq 'P'){'W2_PACK_NOZERO 1'}else{'W2_PACK_NOZERO 0'}
 & "$r\hip-test\build-modules.ps1" -SourceDir "$r\hip-test" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-$set-$Arch" -Only c64-wave2 -Targets $Arch -ExtraDefines $def
 if($LASTEXITCODE){throw 'compile'}
}
if($Arch -eq 'gfx1201'){
 foreach($set in 'Z','P'){
 New-Item -ItemType Directory -Force "$r\flat-$set"|Out-Null
 Copy-Item "$r\flat-A\*.hsaco" "$r\flat-$set" -Force
 Copy-Item "$r\build-$set-$Arch\c64-wave2.hsaco" "$r\flat-$set\c64-wave2.hsaco" -Force
 }
}

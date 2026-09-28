param([string]$Arch='gfx1201')
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\fusion-round3'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile'}){throw 'GPU busy'}
& "$r\hip-down\build-modules.ps1" -SourceDir "$r\hip-down" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-D-$Arch" -Only c64-wave2 -Targets $Arch -ExtraDefines @('W2_DOWN_FUSED 1')
if($LASTEXITCODE){throw 'compile'}
if($Arch -eq 'gfx1201'){New-Item -ItemType Directory -Force "$r\flat-D"|Out-Null;Copy-Item "$r\flat-A\*.hsaco" "$r\flat-D" -Force;Copy-Item "$r\build-D-$Arch\c64-wave2.hsaco" "$r\flat-D" -Force}

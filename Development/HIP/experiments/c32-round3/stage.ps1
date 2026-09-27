$ErrorActionPreference='Stop'
$r='D:\DLSSNR-Lab\hip-backend\c32-round3'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets\HIP'
if(Get-Process SB-Win64-Shipping,LOP-Win64-Shipping,OnimushaWotS,re9 -ErrorAction SilentlyContinue){throw 'Game running'}
if(Test-Path "$r\modules-A\gfx1201\c32-wave1.hsaco"){throw 'Baseline already archived'}
New-Item -ItemType Directory -Force "$r\modules-A","$r\hip"|Out-Null
foreach($a in 'gfx1200','gfx1201'){
 Copy-Item "$g\$a" "$r\modules-A\$a" -Recurse -Force
 "BASE $a $((Get-FileHash "$g\$a\c32-wave1.hsaco").Hash)"
}
Copy-Item "$r\hip" "$r\hip-base" -Recurse -Force
& "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-A" -Only c32-wave1
if($LASTEXITCODE){throw 'build failed'}

$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\vit-bytestream'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets\HIP'
if(Get-Process SB-Win64-Shipping,LOP-Win64-Shipping,OnimushaWotS,re9,benchmark -ErrorAction SilentlyContinue){throw 'GPU busy'}
if(Test-Path "$r\modules-A"){throw 'Baseline exists'}
New-Item -ItemType Directory "$r\modules-A"|Out-Null
Copy-Item 'D:\DLSSNR-Lab\hip-backend\c32-round3\benchmark.exe' "$r\baseline.exe"
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$g\$a" "$r\modules-A\$a" -Recurse}
& "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-stream" -Only vit-stream
if($LASTEXITCODE){throw 'build'}
foreach($v in 'V1','V2','V3'){
 New-Item -ItemType Directory "$r\modules-$v"|Out-Null
 foreach($a in 'gfx1200','gfx1201'){
  Copy-Item "$r\modules-A\$a" "$r\modules-$v\$a" -Recurse
  Copy-Item "$r\build-stream\$a\vit-stream.hsaco" "$r\modules-$v\$a\"
 }
}

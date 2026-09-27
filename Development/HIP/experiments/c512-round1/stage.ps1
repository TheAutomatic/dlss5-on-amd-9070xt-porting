$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c512-round1'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets\HIP'
if(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^benchmark'}){throw 'GPU busy'}
if(Test-Path "$r\modules-A"){throw 'Baseline exists'}
New-Item -ItemType Directory "$r\modules-A"|Out-Null
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$g\$a" "$r\modules-A\$a" -Recurse}
Copy-Item 'D:\DLSSNR-Lab\hip-backend\vit-bytestream\benchmark.exe' "$r\benchmark.exe"

$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\swin-body-gap-20261001';$s='D:\DLSSNR-Lab\hip-backend\input-slim-20261001'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall'}){throw 'game running'}
New-Item -ItemType Directory -Force "$root\flat-A"|Out-Null
$files=@(Get-ChildItem "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201" -Filter '*.hsaco');if($files.Count -ne 31){throw 'Expected 31'}
Copy-Item ($files|ForEach-Object FullName) "$root\flat-A" -Force
"c64-wave2 installed $((Get-FileHash "$root\flat-A\c64-wave2.hsaco").Hash)"
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1'){(Get-Content "$s\$f" -Raw).Replace('input-slim-20261001\assets-base','KEEPASSETS').Replace('input-slim-20261001','swin-body-gap-20261001').Replace('KEEPASSETS','input-slim-20261001\assets-base')|Set-Content "$root\$f"}
'SETUP_DONE'

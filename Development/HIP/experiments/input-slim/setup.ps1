# input-slim-20261001: lab snapshot of installed Stellar modules (flat-A) + base assets; hosts uploaded separately.
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\input-slim-20261001'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall'}){throw 'game running'}
New-Item -ItemType Directory -Force "$root\flat-A"|Out-Null
$files=@(Get-ChildItem "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201" -Filter '*.hsaco');if($files.Count -ne 31){throw 'Expected 31'}
Copy-Item ($files|ForEach-Object FullName) "$root\flat-A" -Force
if(Test-Path "$root\assets-base"){Remove-Item "$root\assets-base" -Recurse -Force}
Copy-Item 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' "$root\assets-base" -Recurse
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash)"
"flags:";Get-Content "$game\DLSS5-AMD\native-game-flags.txt"
'SETUP_DONE'

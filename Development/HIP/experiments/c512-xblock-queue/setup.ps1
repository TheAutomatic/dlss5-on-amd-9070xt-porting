# c512-xblock-queue-20261001: flat-A = installed Stellar Blade 31 gfx1201 modules; regression.ps1 from c512-compact-vt; hosts A/X uploaded.
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\c512-xblock-queue-20261001';$prev='D:\DLSSNR-Lab\hip-backend\c512-compact-vt-20260930'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
New-Item -ItemType Directory -Force "$root\flat-A"|Out-Null
$files=@(Get-ChildItem "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201" -Filter '*.hsaco');if($files.Count -ne 31){throw 'Expected 31'}
Copy-Item ($files|ForEach-Object FullName) "$root\flat-A" -Force
(Get-Content "$prev\regression.ps1" -Raw).Replace('c512-compact-vt-20260930','c512-xblock-queue-20261001')|Set-Content "$root\regression.ps1"
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash)"
Get-ChildItem "$root\*.exe"|ForEach-Object{"$($_.Name) $((Get-FileHash $_.FullName).Hash)"}
'SETUP_DONE'

# ideas-yi (2026-10-02, results/ideas-yami-ikaruga-20261002) setup: harness from outside-net, flat-A = installed Stellar gfx1201 modules.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\ideas-yi-20261002';$s='D:\DLSSNR-Lab\hip-backend\outside-net-20261002'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1','full.ps1'){(Get-Content "$s\$f" -Raw).Replace('outside-net-20261002','ideas-yi-20261002')|Set-Content "$root\$f"}
if((Get-Content "$root\regression.ps1" -Raw) -notmatch 'ADAPTIVE_IDLE_MS=1000000000'){throw 'idle pin missing'}
Remove-Item "$root\flat-A" -Recurse -Force -EA 0;Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201" "$root\flat-A" -Recurse
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash.Substring(0,8)) sums $((Get-FileHash "$game\DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS").Hash.Substring(0,8)) flatA $(@(gci "$root\flat-A" -Filter *.hsaco).Count)"
'SETUP_DONE'

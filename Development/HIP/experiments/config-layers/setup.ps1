# config-layers (2026-10-03, results/config-layers-20261003) setup: harness from multi-pass; flat-A = flat-M = installed Stellar gfx1201
# (no module changes). benchmark-base = main d349cc92 host, benchmark-M(+Mroll) = branch host. Hosts uploaded to bin\ first.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\config-layers-20261003';$s='D:\DLSSNR-Lab\hip-backend\multi-pass-20261003'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1','full.ps1','regression-cmp.ps1'){(Get-Content "$s\$f" -Raw).Replace('multi-pass-20261003','config-layers-20261003')|Set-Content "$root\$f"}
if((Get-Content "$root\regression.ps1" -Raw) -notmatch 'ADAPTIVE_IDLE_MS=1000000000'){throw 'idle pin missing'}
if(!(Test-Path "$root\assets-base")){Copy-Item "$s\assets-base" "$root\assets-base" -Recurse}
foreach($n in 'A','M'){Remove-Item "$root\flat-$n" -Recurse -Force -EA 0;Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201" "$root\flat-$n" -Recurse}
Copy-Item "$root\bin\benchmark-base.exe","$root\bin\benchmark-M.exe" $root -Force;Copy-Item "$root\bin\benchmark-M.exe" "$root\benchmark-Mroll.exe" -Force
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash.Substring(0,8)) sums $((Get-FileHash "$game\DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS").Hash.Substring(0,8)) flatA $(@(gci "$root\flat-A" -Filter *.hsaco).Count)"
Get-ChildItem "$root\*.exe","$root\bin\*"|%{"$($_.Name) $((Get-FileHash $_.FullName).Hash.Substring(0,8))"}
& "$root\bin\tcl.exe" | Select-Object -Last 3
'SETUP_DONE'

# rtz1080 (2026-10-03, results/ideas-yami-ikaruga-20261002 section 4) setup: harness from ideas-yi; flat-A = installed Stellar gfx1201;
# flat-T = flat-A + c32-wave1-rtz.hsaco (LLVM23 prebuilt, HIP_C32_RTZ_ISA 2); benchmark-T = host with HIP_C32_RTZ_TALL (1080 tier loads the rtz file).
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\rtz1080-20261003';$s='D:\DLSSNR-Lab\hip-backend\ideas-yi-20261002'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1','full.ps1'){(Get-Content "$s\$f" -Raw).Replace('ideas-yi-20261002','rtz1080-20261003')|Set-Content "$root\$f"}
if((Get-Content "$root\regression.ps1" -Raw) -notmatch 'ADAPTIVE_IDLE_MS=1000000000'){throw 'idle pin missing'}
foreach($n in 'A','T'){Remove-Item "$root\flat-$n" -Recurse -Force -EA 0;Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201" "$root\flat-$n" -Recurse}
Copy-Item "$root\pre23\gfx1201\c32-wave1-rtz.hsaco" "$root\flat-T\" -Force
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash.Substring(0,8)) flatA $(@(gci "$root\flat-A" -Filter *.hsaco).Count) flatT $(@(gci "$root\flat-T" -Filter *.hsaco).Count) rtz $((Get-FileHash "$root\flat-T\c32-wave1-rtz.hsaco").Hash.Substring(0,8))"
Get-ChildItem "$root\*.exe"|%{"$($_.Name) $((Get-FileHash $_.FullName).Hash.Substring(0,8))"}
(Get-Content "$root\regression.ps1" -Raw).Replace('Count -ne 31){','Count -lt 31){')|Set-Content "$root\regression.ps1"  # flat-T has 32 modules
'SETUP_DONE'

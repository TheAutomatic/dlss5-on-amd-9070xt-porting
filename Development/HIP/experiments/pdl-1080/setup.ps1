# pdl-1080 (2026-10-02) setup: harness from net-timing-20261002 (idle pinned), all sides on the installed modules (next-candidate flat-N, F6411153).
# base = benchmark-base.exe (main host), P = benchmark-P.exe (C256 boundary blocks at 1080 on the split PDL path when C256 is persistent), Proll = P copy.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\pdl-1080-20261002';$s='D:\DLSSNR-Lab\hip-backend\net-timing-20261002';$n='D:\DLSSNR-Lab\hip-backend\next-candidate-20261002'
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1','full.ps1'){(Get-Content "$s\$f" -Raw).Replace('net-timing-20261002','pdl-1080-20261002')|Set-Content "$root\$f"}
if((Get-Content "$root\regression.ps1" -Raw) -notmatch 'ADAPTIVE_IDLE_MS=1000000000'){throw 'idle pin missing'}
foreach($x in 'A','P'){Remove-Item "$root\flat-$x" -Recurse -Force -EA 0;New-Item -ItemType Directory "$root\flat-$x"|Out-Null;Copy-Item "$n\flat-N\*.hsaco" "$root\flat-$x"}
Remove-Item "$root\assets-base" -Recurse -Force -EA 0;Copy-Item "$n\assets-base" "$root\assets-base" -Recurse
Copy-Item "$root\bin\benchmark-base.exe","$root\bin\benchmark-P.exe" $root -Force;Copy-Item "$root\bin\benchmark-P.exe" "$root\benchmark-Proll.exe" -Force
foreach($x in 'A','P'){"flat$x $(@(gci "$root\flat-$x" -Filter *.hsaco).Count)"}
Get-ChildItem "$root\*.exe","$root\bin\rt-*\*.dll"|%{"$($_.Name) $((Get-FileHash $_.FullName).Hash.Substring(0,8))"}
'SETUP_DONE'

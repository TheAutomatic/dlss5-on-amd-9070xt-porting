# net-timing (2026-10-02) setup: harness from next-candidate-20261002 (idle pinned), all sides on the installed modules (flat-N there).
# base = benchmark-base.exe (main 8af86240 host), T = benchmark-T.exe (net-timing host; DLSS5_NET_TIMING off by default), Troll = T copy.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\net-timing-20261002';$s='D:\DLSSNR-Lab\hip-backend\next-candidate-20261002'
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1','full.ps1'){(Get-Content "$s\$f" -Raw).Replace('next-candidate-20261002','net-timing-20261002')|Set-Content "$root\$f"}
if((Get-Content "$root\regression.ps1" -Raw) -notmatch 'ADAPTIVE_IDLE_MS=1000000000'){throw 'idle pin missing'}
foreach($n in 'A','T','E'){Remove-Item "$root\flat-$n" -Recurse -Force -EA 0;New-Item -ItemType Directory "$root\flat-$n"|Out-Null;Copy-Item "$s\flat-N\*.hsaco" "$root\flat-$n"}
Remove-Item "$root\assets-base" -Recurse -Force -EA 0;Copy-Item "$s\assets-base" "$root\assets-base" -Recurse
Copy-Item "$root\bin\benchmark-base.exe","$root\bin\benchmark-T.exe" $root -Force;Copy-Item "$root\bin\benchmark-T.exe" "$root\benchmark-Troll.exe" -Force
foreach($n in 'A','T','E'){"flat$n $(@(gci "$root\flat-$n" -Filter *.hsaco).Count)"}
Get-ChildItem "$root\*.exe","$root\bin\*.dll"|%{"$($_.Name) $((Get-FileHash $_.FullName).Hash.Substring(0,8))"}
'SETUP_DONE'

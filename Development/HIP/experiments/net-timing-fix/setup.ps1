# net-timing-fix (2026-10-02, results/net-timing-20261002 #3) setup: harness, flat module dirs, assets and templates from net-timing-20261002.
# base = benchmark-base.exe (main host), T = benchmark-T.exe (end-event query fix), Troll = T copy; bin\rt-old / rt-new runtimes.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\net-timing-fix-20261002';$s='D:\DLSSNR-Lab\hip-backend\net-timing-20261002'
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1','full.ps1'){(Get-Content "$s\$f" -Raw).Replace('net-timing-20261002','net-timing-fix-20261002')|Set-Content "$root\$f"}
if((Get-Content "$root\regression.ps1" -Raw) -notmatch 'ADAPTIVE_IDLE_MS=1000000000'){throw 'idle pin missing'}
foreach($n in 'A','T','E'){Remove-Item "$root\flat-$n" -Recurse -Force -EA 0;Copy-Item "$s\flat-$n" "$root\flat-$n" -Recurse}
Remove-Item "$root\assets-base","$root\templates" -Recurse -Force -EA 0;Copy-Item "$s\assets-base" "$root\assets-base" -Recurse;Copy-Item "$s\templates" "$root\templates" -Recurse
Copy-Item "$root\bin\benchmark-base.exe","$root\bin\benchmark-T.exe" $root -Force;Copy-Item "$root\bin\benchmark-T.exe" "$root\benchmark-Troll.exe" -Force
foreach($n in 'A','T','E'){"flat$n $(@(gci "$root\flat-$n" -Filter *.hsaco).Count)"}
Get-ChildItem "$root\*.exe","$root\bin\*.exe","$root\bin\rt-*\*.dll"|%{"$($_.FullName.Substring($root.Length+1)) $((Get-FileHash $_.FullName).Hash.Substring(0,8))"}
'SETUP_DONE'

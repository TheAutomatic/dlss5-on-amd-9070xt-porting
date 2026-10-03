# pending-review-20261003 setup: harness from multi-pass-skip-20261003; flat-A = installed Stellar gfx1201 (SUMS F3EFDC16).
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\pending-review-20261003'
$s='D:\DLSSNR-Lab\hip-backend\multi-pass-skip-20261003'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall'}){throw 'game running'}
New-Item -ItemType Directory -Force $root|Out-Null
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1','full.ps1','regression-cmp.ps1'){(Get-Content "$s\$f" -Raw).Replace('multi-pass-skip-20261003','pending-review-20261003')|Set-Content "$root\$f"}
if((Get-Content "$root\regression.ps1" -Raw) -notmatch 'ADAPTIVE_IDLE_MS=1000000000'){throw 'idle pin missing'}
if(!(Test-Path "$root\assets-base")){Copy-Item "$s\assets-base" "$root\assets-base" -Recurse}
# hosts: identical exe on all sides (module swaps / env-flag candidate)
Copy-Item "$s\bin\benchmark-base.exe" "$root\benchmark-base.exe" -Force
Copy-Item "$s\bin\benchmark-base.exe" "$root\benchmark-P.exe" -Force
Copy-Item "$s\bin\benchmark-base.exe" "$root\benchmark-Proll.exe" -Force
Remove-Item "$root\flat-A" -Recurse -Force -EA 0
Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201" "$root\flat-A" -Recurse
$n=@(Get-ChildItem "$root\flat-A" -Filter *.hsaco).Count
$sums=(Get-FileHash "$game\DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS").Hash.Substring(0,8)
$addon=(Get-FileHash "$game\dlss5-amd.addon64").Hash.Substring(0,8)
if($n -lt 31){throw "flat-A incomplete ($n)"}
"addon $addon sums $sums flatA $n"
Get-ChildItem "$root\*.exe"|%{"$($_.Name) $((Get-FileHash $_.FullName).Hash.Substring(0,8))"}
'SETUP_DONE'

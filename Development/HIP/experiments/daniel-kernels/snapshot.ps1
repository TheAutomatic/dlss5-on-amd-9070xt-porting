$ErrorActionPreference='Stop'
$r='D:\DLSSNR-Lab\hip-backend\daniel-kernels'
if(Get-Process | Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile'}){throw 'GPU busy'}
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
$hip="$g\DLSS5-AMD\native-game-tiled-assets\HIP"
New-Item -ItemType Directory -Force $r,"$r\flat-A","$r\baseline-gfx1200" | Out-Null
$before=@{};foreach($f in Get-ChildItem $hip -Recurse -Filter '*.hsaco'){$before[$f.FullName]=(Get-FileHash $f.FullName).Hash}
foreach($f in @("$g\dlss5-amd.addon64","$g\dxgi.dll","$g\OptiScaler.ini","$g\DLSS5-AMD\native-game-flags.txt")){$before[$f]=(Get-FileHash $f).Hash}
$before|ConvertTo-Json|Set-Content "$r\before.json"
Copy-Item "$hip\gfx1201\*.hsaco" "$r\flat-A" -Force
Copy-Item "$hip\gfx1200\*.hsaco" "$r\baseline-gfx1200" -Force
Copy-Item 'D:\DLSSNR-Lab\zero-copy-io-20260928\benchmark-zc.exe' "$r\benchmark-zc.exe" -Force
if(@(Get-ChildItem "$r\flat-A" -Filter '*.hsaco').Count -ne 30){throw 'module count'}
Write-Output 'Snapshot: 60 modules and 4 protected host/config files'

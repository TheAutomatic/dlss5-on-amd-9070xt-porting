# c32-align-20260930: snapshot installed Stellar Blade set, flat-A baseline, base host from shift-pack lab.
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\c32-align-20260930'
$prev='D:\DLSSNR-Lab\hip-backend\shift-pack-900-20260930'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile|^jobbench|^Magpie'}){throw 'GPU busy'}
New-Item -ItemType Directory -Force "$root\flat-A","$root\baseline\gfx1200","$root\baseline\gfx1201"|Out-Null
$rows=@()
foreach($arch in 'gfx1200','gfx1201'){$files=@(Get-ChildItem "$game\DLSS5-AMD\native-game-tiled-assets\HIP\$arch" -Filter '*.hsaco');if($files.Count -ne 31){throw 'Expected 31'}
 foreach($f in $files){Copy-Item $f.FullName "$root\baseline\$arch\$($f.Name)";$rows+=@{path=$f.FullName;sha256=(Get-FileHash $f.FullName).Hash}}}
foreach($f in @("$game\dlss5-amd.addon64","$game\dxgi.dll","$game\OptiScaler.ini","$game\DLSS5-AMD\native-game-flags.txt")){$rows+=@{path=$f;sha256=(Get-FileHash $f).Hash}}
$rows|ConvertTo-Json -Depth 5|Set-Content "$root\snapshot.json"
Copy-Item "$game\DLSS5-AMD\native-game-flags.txt" "$root\base-flags.txt"
Copy-Item "$root\baseline\gfx1201\*.hsaco" "$root\flat-A"
Copy-Item "$prev\benchmark-P.exe" "$root\benchmark-base.exe";Copy-Item "$prev\regression.ps1" $root
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash)"
foreach($f in Get-ChildItem "$root\flat-A"){if((Get-FileHash $f.FullName).Hash -ne (Get-FileHash "$prev\flat-P\$($f.Name)").Hash){"DIFF vs shift-pack flat-P $($f.Name)"}}
'SETUP_DONE'

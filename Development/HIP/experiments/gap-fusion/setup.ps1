# gap-fusion-20260930: snapshot installed Stellar Blade (add-on 6d059845 + 31 modules after hoist-loads) as flat-A; base host from hoist-loads.
# Uploaded beforehand: src.zip (hip/ at this commit), benchmark-P.exe / benchmark-Proll.exe (gather-fold host), benchmark-A.exe (same source, HIP_VIT_GATHER_FOLD_HOST=0).
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\gap-fusion-20260930';$prev='D:\DLSSNR-Lab\hip-backend\hoist-loads-20260930'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile|^jobbench|^Magpie'}){throw 'GPU busy'}
New-Item -ItemType Directory -Force "$root\flat-A","$root\baseline\gfx1200","$root\baseline\gfx1201"|Out-Null
$rows=@()
foreach($arch in 'gfx1200','gfx1201'){$files=@(Get-ChildItem "$game\DLSS5-AMD\native-game-tiled-assets\HIP\$arch" -Filter '*.hsaco');if($files.Count -ne 31){throw 'Expected 31'}
 foreach($f in $files){Copy-Item $f.FullName "$root\baseline\$arch\$($f.Name)" -Force;$rows+=@{path=$f.FullName;sha256=(Get-FileHash $f.FullName).Hash}}}
foreach($f in @("$game\dlss5-amd.addon64","$game\dxgi.dll","$game\OptiScaler.ini","$game\DLSS5-AMD\native-game-flags.txt")){$rows+=@{path=$f;sha256=(Get-FileHash $f).Hash}}
$rows|ConvertTo-Json -Depth 5|Set-Content "$root\snapshot.json"
Copy-Item "$root\baseline\gfx1201\*.hsaco" "$root\flat-A" -Force
Copy-Item "$prev\benchmark-base.exe" "$root\benchmark-base.exe" -Force
(Get-Content "$prev\regression.ps1" -Raw).Replace('hoist-loads-20260930','gap-fusion-20260930')|Set-Content "$root\regression.ps1"
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash)"
'SETUP_DONE'

# w16-c64-c128-20260930: snapshot installed Stellar Blade (add-on 6d059845 + 31 modules) as flat-A; base host = installed-host source benchmark-base (from c512-compact-vt). Uploaded: src.zip (worktree hip/), benchmark-H (origin/main 7b821c7f), benchmark-P/Pdiag (+ this patch), dlss5-amd.addon64, LmxxfNrRuntime.dll.
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\w16-c64-c128-20260930';$prev='D:\DLSSNR-Lab\hip-backend\c512-compact-vt-20260930'
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
(Get-Content "$prev\regression.ps1" -Raw).Replace('c512-compact-vt-20260930','w16-c64-c128-20260930')|Set-Content "$root\regression.ps1"
if(Test-Path "$root\src"){Remove-Item "$root\src" -Recurse -Force};Expand-Archive "$root\src.zip" "$root\src" -Force
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash)"
"c64-wave2 1201 installed $((Get-FileHash "$root\baseline\gfx1201\c64-wave2.hsaco").Hash)"
'SETUP_DONE'

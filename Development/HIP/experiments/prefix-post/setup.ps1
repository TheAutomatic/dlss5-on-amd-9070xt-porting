# prefix-post-20260930: snapshot installed Stellar Blade (bb7ebfd1 + 31 modules), flat-A; base host = c256-w16 benchmark-P (bb7ebfd1 source = 7ca25c98 + W16 host patch).
# Uploaded beforehand into $root: src.zip (hip/ with CW_PREPOST_BYTE), benchmark-P/Ppre/Ppost/Proll.exe (7ca25c98 + W16 + prefix-post host patch), dlss5-amd.addon64, LmxxfNrRuntime.dll.
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\prefix-post-20260930';$prev='D:\DLSSNR-Lab\hip-backend\c256-w16-20260930'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile|^jobbench|^Magpie'}){throw 'GPU busy'}
New-Item -ItemType Directory -Force "$root\flat-A","$root\baseline\gfx1200","$root\baseline\gfx1201"|Out-Null
$rows=@()
foreach($arch in 'gfx1200','gfx1201'){$files=@(Get-ChildItem "$game\DLSS5-AMD\native-game-tiled-assets\HIP\$arch" -Filter '*.hsaco');if($files.Count -ne 31){throw 'Expected 31'}
 foreach($f in $files){Copy-Item $f.FullName "$root\baseline\$arch\$($f.Name)";$rows+=@{path=$f.FullName;sha256=(Get-FileHash $f.FullName).Hash}}}
foreach($f in @("$game\dlss5-amd.addon64","$game\dxgi.dll","$game\OptiScaler.ini","$game\DLSS5-AMD\native-game-flags.txt")){$rows+=@{path=$f;sha256=(Get-FileHash $f).Hash}}
$rows|ConvertTo-Json -Depth 5|Set-Content "$root\snapshot.json"
Copy-Item "$root\baseline\gfx1201\*.hsaco" "$root\flat-A"
Copy-Item "$prev\benchmark-P.exe" "$root\benchmark-base.exe";Copy-Item "$prev\regression.ps1" $root
(Get-Content "$root\regression.ps1" -Raw).Replace('c256-w16-20260930','prefix-post-20260930')|Set-Content "$root\regression.ps1"
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash)"
'SETUP_DONE'

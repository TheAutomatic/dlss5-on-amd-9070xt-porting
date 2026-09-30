# mochizuki-gap-20261001: snapshot installed Stellar Blade (31 modules incl. hoist-loads) as flat-A; hosts + regression.ps1 from hoist-loads. src.zip uploaded beforehand.
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001';$prev='D:\DLSSNR-Lab\hip-backend\hoist-loads-20260930'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile|^jobbench|^Magpie'}){throw 'GPU busy'}
New-Item -ItemType Directory -Force "$root\flat-A","$root\baseline\gfx1200","$root\baseline\gfx1201"|Out-Null
$rows=@()
foreach($arch in 'gfx1200','gfx1201'){$files=@(Get-ChildItem "$game\DLSS5-AMD\native-game-tiled-assets\HIP\$arch" -Filter '*.hsaco');if($files.Count -ne 31){throw 'Expected 31'}
 foreach($f in $files){Copy-Item $f.FullName "$root\baseline\$arch\$($f.Name)" -Force;$rows+=@{path=$f.FullName;sha256=(Get-FileHash $f.FullName).Hash}}}
foreach($f in @("$game\dlss5-amd.addon64","$game\dxgi.dll","$game\OptiScaler.ini","$game\DLSS5-AMD\native-game-flags.txt")){$rows+=@{path=$f;sha256=(Get-FileHash $f).Hash}}
$rows|ConvertTo-Json -Depth 5|Set-Content "$root\snapshot.json"
Copy-Item "$root\baseline\gfx1201\*.hsaco" "$root\flat-A" -Force
foreach($x in 'benchmark-base.exe','benchmark-P.exe','benchmark-Proll.exe'){Copy-Item "$prev\$x" "$root\$x" -Force}
(Get-Content "$prev\regression.ps1" -Raw).Replace('hoist-loads-20260930','mochizuki-gap-20261001')|Set-Content "$root\regression.ps1"
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash)"
"c512-m32-mh 1201 installed $((Get-FileHash "$root\baseline\gfx1201\c512-m32-mh.hsaco").Hash)"
'SETUP_DONE'

$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\geom1088-20260930'
$prev='D:\DLSSNR-Lab\hip-backend\c32-align-20260930'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile|^jobbench|^Magpie'}){throw 'GPU busy'}
New-Item -ItemType Directory -Force "$root\flat-A"|Out-Null
$files=@(Get-ChildItem "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201" -Filter '*.hsaco');if($files.Count -ne 31){throw 'Expected 31'}
Copy-Item ($files|%{$_.FullName}) "$root\flat-A"
Copy-Item "$game\DLSS5-AMD\native-game-flags.txt" "$root\base-flags.txt"
Copy-Item "$prev\regression.ps1" $root
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash)"
'SETUP_DONE'

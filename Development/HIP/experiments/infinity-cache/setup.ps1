$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\infinity-cache-20260930'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^Magpie'}){throw 'GPU busy'}
New-Item -ItemType Directory -Force "$root\flat-A","$root\flat-P"|Out-Null
Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\flat-A"
Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\flat-P"
Copy-Item "$game\DLSS5-AMD\native-game-flags.txt" "$root\base-flags.txt"
Copy-Item 'D:\DLSSNR-Lab\hip-backend\shift-pack-900-20260930\regression.ps1' $root
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash)"
"mods $(@(Get-ChildItem "$root\flat-A" -Filter *.hsaco).Count)"
'SETUP_DONE'

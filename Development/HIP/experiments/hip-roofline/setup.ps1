$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\hip-roofline-20260930';$k='D:\DLSSNR-Lab\hip-backend\kernel-map-v3-20260930'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
New-Item -ItemType Directory -Force "$root\flat-C"|Out-Null
Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\flat-C" -Force
Copy-Item "$k\benchmark-base.exe","$k\evprof.exe" $root -Force
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash.Substring(0,8))"
foreach($f in Get-ChildItem "$root\flat-C" -Filter *.hsaco){$h=(Get-FileHash $f.FullName).Hash;$o=(Get-FileHash "$k\flat-A\$($f.Name)").Hash;if($h -ne $o){"CHANGED $($f.Name) $($o.Substring(0,8))->$($h.Substring(0,8))"}}
"count $(@(Get-ChildItem "$root\flat-C" -Filter *.hsaco).Count)"

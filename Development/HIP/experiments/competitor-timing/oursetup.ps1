$root='D:\DLSSNR-Lab\competitor-timing-20260930\ours';$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
New-Item -ItemType Directory -Force "$root\flat"|Out-Null
Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\flat" -Force
Copy-Item D:\DLSSNR-Lab\geom1088-20260930\benchmark-P.exe $root -Force
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash.Substring(0,8)) dxgi $((Get-FileHash "$game\dxgi.dll").Hash.Substring(0,8))"
foreach($f in Get-ChildItem "$root\flat" -Filter *.hsaco){$h=(Get-FileHash $f.FullName).Hash;$o=(Get-FileHash "D:\DLSSNR-Lab\hip-backend\hip-roofline-20260930\flat-C\$($f.Name)" -ea 0).Hash;if($h -ne $o){"DIFF-vs-roofline $($f.Name)"}}
"count $(@(Get-ChildItem "$root\flat" -Filter *.hsaco).Count)"
& D:\DLSSNR-Lab\daniel-051\swap.ps1 status

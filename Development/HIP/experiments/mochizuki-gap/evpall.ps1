$r='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001';$e="$r\evp";$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
Remove-Item -Recurse -Force $e -EA 0;New-Item -ItemType Directory -Force "$e\flat-C"|Out-Null
Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$e\flat-C";Copy-Item "$r\evprof-P3.exe" $e
foreach($h in 900,1080){& "$r\evp.ps1" -Height $h -Exe evprof-P3.exe -Tag prof -Frames 300 -Span 1 -Profile 1}
Get-ChildItem $e -Recurse -Include *.f16,*.ppm|Remove-Item -Force

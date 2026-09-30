# whole-network HIP span, installed Stellar modules + HEAD host (P6); 900/1152, 1080/1152, 1080/1088, two rounds
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001\ours';$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
Remove-Item -Recurse -Force $root -EA 0;New-Item -ItemType Directory -Force "$root\flat"|Out-Null
Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\flat";Copy-Item D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001\benchmark-P6.exe "$root\benchmark-P.exe"
foreach($r in 1,2){foreach($c in @(@(900,1152),@(1080,1152),@(1080,1088))){& D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001\ours.ps1 -Height $c[0] -Rows $c[1] -Span 1 -Tag "span$r"}}
Get-ChildItem $root -Recurse -Include *.f16,*.ppm|Remove-Item -Force

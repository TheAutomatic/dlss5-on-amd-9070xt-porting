# FW2 re-test on the current Stellar install (flat-D, c64-wave2 0D043F91): base flat-D, cand flat-D + FW2 c512-m32-deep, host P5 (HEAD) both sides; 19 bit-exact + 3 ABBA
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001';$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
Remove-Item -Recurse -Force "$root\flat-D","$root\flat-FW2D","$root\runtime-regression-FW2D-*" -EA 0
New-Item -ItemType Directory -Force "$root\flat-D","$root\flat-FW2D"|Out-Null
Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\flat-D";Copy-Item "$root\flat-D\*" "$root\flat-FW2D";Copy-Item "$root\cand-FW2\c512-m32-deep.hsaco" "$root\flat-FW2D" -Force
"c64-wave2 $((Get-FileHash "$root\flat-D\c64-wave2.hsaco").Hash.Substring(0,8)) c512-m32-deep $((Get-FileHash "$root\flat-D\c512-m32-deep.hsaco").Hash.Substring(0,8))"
& "$root\full.ps1" -BaseSet D -BaseBench benchmark-P5.exe -Set FW2D -Cand P5 -RollHost P5 -Rounds 3 *> "$root\full-FW2D.log"
"SAME count $((Select-String "$root\full-FW2D.log" -Pattern '^SAME|AE CSV SAME').Count)"
& "$root\summarize.ps1" -Sets FW2D

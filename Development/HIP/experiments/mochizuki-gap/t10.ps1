# FW2 re-test on the install after U4 (flat-E): base flat-E, cand flat-E + FW2 c512-m32-deep, host P5; 19 bit-exact + 3 ABBA
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001';$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
Remove-Item -Recurse -Force "$root\flat-E","$root\flat-FW2E","$root\runtime-regression-FW2E-*" -EA 0
New-Item -ItemType Directory -Force "$root\flat-E","$root\flat-FW2E"|Out-Null
Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\flat-E";Copy-Item "$root\flat-E\*" "$root\flat-FW2E";Copy-Item "$root\cand-FW2\c512-m32-deep.hsaco" "$root\flat-FW2E" -Force
"c64-wave2 $((Get-FileHash "$root\flat-E\c64-wave2.hsaco").Hash.Substring(0,8)) c512-m32-deep $((Get-FileHash "$root\flat-E\c512-m32-deep.hsaco").Hash.Substring(0,8))"
& "$root\full.ps1" -BaseSet E -BaseBench benchmark-P5.exe -Set FW2E -Cand P5 -RollHost P5 -Rounds 3 *> "$root\full-FW2E.log"
"SAME count $((Select-String "$root\full-FW2E.log" -Pattern '^SAME|AE CSV SAME').Count)"
& "$root\summarize.ps1" -Sets FW2E

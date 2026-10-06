# merged host P3 (swin W2_UP_LOW_BYTES + FFN_ONE): flat-C = current installed Stellar modules; C+FF vs C, both on P3, correctness (19)
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
Remove-Item -Recurse -Force "$root\flat-C","$root\flat-CF","$root\runtime-regression-CF-*" -EA 0
New-Item -ItemType Directory -Force "$root\flat-C","$root\flat-CF"|Out-Null
Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\flat-C";Copy-Item "$root\flat-C\*" "$root\flat-CF"
Copy-Item "$root\build-final\gfx1201\c512-m32-deep.hsaco" "$root\flat-CF" -Force
& "$root\full.ps1" -BaseSet C -BaseBench benchmark-P3.exe -Set CF -Cand P3 -RollHost P3 -SkipTiming *> "$root\full-CF.log"
(Select-String "$root\full-CF.log" -Pattern '^SAME|AE CSV SAME').Count

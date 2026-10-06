# B8 = FF + byte-residual modules; base = FF set on host P1, candidate = B8 on host P2; bit-exact (19) + 3 ABBA.
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001'
Remove-Item -Recurse -Force "$root\runtime-regression-B8-*","$root\flat-B8" -EA 0
& "$root\mkset.ps1" -Name B8 -Builds FF,B8d,B8m
& "$root\full.ps1" -BaseSet FF -BaseBench benchmark-P1.exe -Set B8 -Cand P2 -RollHost P2roll -Rounds 3 *> "$root\full-B8.log"
& "$root\summarize.ps1" -Sets B8

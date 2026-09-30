# U4 = flat-D + c512-m32-mh (FUSEQKV + C512_COMPACT_QKV_UNROLL 4); base flat-D; host P5; 19 bit-exact + 3 ABBA
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001'
Remove-Item -Recurse -Force "$root\flat-U4D","$root\runtime-regression-U4D-*" -EA 0
New-Item -ItemType Directory -Force "$root\flat-U4D"|Out-Null;Copy-Item "$root\flat-D\*" "$root\flat-U4D";Copy-Item "$root\cand-U4\c512-m32-mh.hsaco" "$root\flat-U4D" -Force
& "$root\full.ps1" -BaseSet D -BaseBench benchmark-P5.exe -Set U4D -Cand P5 -RollHost P5 -Rounds 3 *> "$root\full-U4D.log"
"SAME count $((Select-String "$root\full-U4D.log" -Pattern '^SAME|AE CSV SAME').Count)"
& "$root\summarize.ps1" -Sets U4D

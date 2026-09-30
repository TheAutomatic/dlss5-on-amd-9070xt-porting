# QP = installed set (flat-CF) + c512-m32-mh with C512_COMPACT_QKV_PIPE; base = flat-CF; host P3 both sides; 19 bit-exact + 3 ABBA
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001'
Remove-Item -Recurse -Force "$root\flat-QP","$root\runtime-regression-QP-*" -EA 0
New-Item -ItemType Directory -Force "$root\flat-QP"|Out-Null;Copy-Item "$root\flat-CF\*" "$root\flat-QP";Copy-Item "$root\cand-QP\c512-m32-mh.hsaco" "$root\flat-QP" -Force
& "$root\full.ps1" -BaseSet CF -BaseBench benchmark-P3.exe -Set QP -Cand P3 -RollHost P3 -Rounds 3 *> "$root\full-QP.log"
"SAME count $((Select-String "$root\full-QP.log" -Pattern '^SAME|AE CSV SAME').Count)"
& "$root\summarize.ps1" -Sets QP

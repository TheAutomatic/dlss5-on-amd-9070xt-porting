# FW2 = flat-CF + c512-m32-deep (C512_FFN_ONE 2, split_ffn_one_w2) on host P4; base flat-CF on P3; 19 bit-exact + 3 ABBA
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001'
Remove-Item -Recurse -Force "$root\flat-FW2","$root\runtime-regression-FW2-*" -EA 0
New-Item -ItemType Directory -Force "$root\flat-FW2"|Out-Null;Copy-Item "$root\flat-CF\*" "$root\flat-FW2";Copy-Item "$root\cand-FW2\c512-m32-deep.hsaco" "$root\flat-FW2" -Force
& "$root\full.ps1" -BaseSet CF -BaseBench benchmark-P3.exe -Set FW2 -Cand P4 -RollHost P4 -Rounds 3 *> "$root\full-FW2.log"
"SAME count $((Select-String "$root\full-FW2.log" -Pattern '^SAME|AE CSV SAME').Count)"
& "$root\summarize.ps1" -Sets FW2

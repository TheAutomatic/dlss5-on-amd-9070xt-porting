# W2_UP_VEC candidate: flat-UV = flat-A (installed Stellar modules) + c64-wave2 built with W2_UP_VEC 1; 19 groups + 3 ABBA rounds
$root='D:\DLSSNR-Lab\hip-backend\c128-c64-inchain-20261001';$Set='UV'
& "$root\setup.ps1"
$t=Get-Content "$root\regression.ps1" -Raw;$t=$t.Replace('|^rtc_compile','');Set-Content "$root\regression.ps1" $t
Get-ChildItem $root -Directory -Filter 'runtime-regression-*'|Remove-Item -Recurse -Force
New-Item -ItemType Directory -Force "$root\flat-$Set"|Out-Null;Copy-Item "$root\flat-A\*.hsaco" "$root\flat-$Set" -Force;Copy-Item "$root\build-$Set\gfx1201\c64-wave2.hsaco" "$root\flat-$Set" -Force
"flat-$Set c64-wave2 $((Get-FileHash "$root\flat-$Set\c64-wave2.hsaco").Hash)"
try{& "$root\full.ps1" -Set $Set -Rounds 3 *> "$root\full-$Set.log";'FULL OK'}catch{"FULL FAIL $_"}
"SAME-count: $((Select-String -Path "$root\full-$Set.log" -Pattern '^SAME|AE CSV SAME').Count)"
Get-Content "$root\full-$Set.log" | Select-String 'FAIL|changed|throw|Error|DIFF' | Select-Object -Last 10
& "$root\summarize.ps1" -Sets $Set;& "$root\p99m.ps1" -Set $Set
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force

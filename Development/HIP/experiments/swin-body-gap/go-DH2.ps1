# DH re-verify after rebase onto C512_FFN_ONE: base = main host + installed modules; candidate = rebased host + recipe (final) builds of both modules
$root='D:\DLSSNR-Lab\hip-backend\swin-body-gap-20261001';$Set='DH2'
& "$root\setup.ps1"
$t=Get-Content "$root\regression.ps1" -Raw;$t=$t.Replace('|^rtc_compile','');Set-Content "$root\regression.ps1" $t
Get-ChildItem $root -Directory -Filter 'runtime-regression-*'|Remove-Item -Recurse -Force
Remove-Item "$root\build-final" -Recurse -Force -EA 0
& "$root\build.ps1" -Name final -Module multihead-fast-padded-wave-packed -Both
& "$root\build.ps1" -Name final -Module c64-wave2 -Both
"installed mh $((Get-FileHash "$root\flat-A\multihead-fast-padded-wave-packed.hsaco").Hash)"
New-Item -ItemType Directory -Force "$root\flat-$Set"|Out-Null;Copy-Item "$root\flat-A\*.hsaco" "$root\flat-$Set" -Force
foreach($m in 'multihead-fast-padded-wave-packed','c64-wave2'){Copy-Item "$root\build-final\gfx1201\$m.hsaco" "$root\flat-$Set" -Force}
try{& "$root\full.ps1" -Set $Set -Rounds 3 *> "$root\full-$Set.log";'FULL OK'}catch{"FULL FAIL $_"}
"SAME-count: $((Select-String -Path "$root\full-$Set.log" -Pattern '^SAME|AE CSV SAME').Count)"
Get-Content "$root\full-$Set.log" | Select-String 'FAIL|changed|throw|Error' | Select-Object -Last 10
& "$root\summarize.ps1" -Sets $Set;& "$root\p99m.ps1" -Set $Set
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force

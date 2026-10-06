$root='D:\DLSSNR-Lab\hip-backend\swin-body-gap-20261001';$Set='DH'
Get-ChildItem $root -Directory -Filter 'runtime-regression-*'|Remove-Item -Recurse -Force
& "$root\build.ps1" -Name prod-mh -Module multihead-fast-padded-wave-packed
& "$root\build.ps1" -Name prod-w2 -Module c64-wave2
& "$root\build.ps1" -Name dh-mh -Module multihead-fast-padded-wave-packed -Defs 'MH_POOL_HALF_IN 1'
& "$root\build.ps1" -Name dh-w2 -Module c64-wave2 -Defs 'W2_DOWN_HALF 1'
New-Item -ItemType Directory -Force "$root\flat-$Set"|Out-Null;Copy-Item "$root\flat-A\*.hsaco" "$root\flat-$Set" -Force
Copy-Item "$root\build-dh-mh\gfx1201\multihead-fast-padded-wave-packed.hsaco" "$root\flat-$Set" -Force;Copy-Item "$root\build-dh-w2\gfx1201\c64-wave2.hsaco" "$root\flat-$Set" -Force
try{& "$root\full.ps1" -Set $Set -Rounds 3 *> "$root\full-$Set.log";'FULL OK'}catch{"FULL FAIL $_"}
"SAME count: $((Select-String -Path "$root\full-$Set.log" -Pattern '^SAME|AE CSV SAME').Count)"
Get-Content "$root\full-$Set.log" | Select-String 'FAIL|changed|DONE|throw|Error' | Select-Object -Last 10
& "$root\summarize.ps1" -Sets $Set;& "$root\p99m.ps1" -Set $Set
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force

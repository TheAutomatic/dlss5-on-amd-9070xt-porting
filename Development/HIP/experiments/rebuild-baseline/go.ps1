# go.ps1: H = HEAD host + HEAD modules + HEAD shaders vs A = installed (host e22d15a2 bench) ; 19 groups + 3 ABBA
$root='D:\DLSSNR-Lab\hip-backend\rebuild-baseline-20261001'
Get-ChildItem $root -Directory -Filter "runtime-regression-H-*"|Remove-Item -Recurse -Force
try{& "$root\full.ps1" -Set H -Rounds 3 -CandAssets -CandHost H -RollHost Hroll *> "$root\full-H.log";'FULL OK'}catch{"FULL FAIL $_"}
"SAME-count: $((Select-String -Path "$root\full-H.log" -Pattern '^SAME|AE CSV SAME').Count)"
Get-Content "$root\full-H.log" | Select-String 'FAIL|changed|throw|Error|DIFF' | Select-Object -Last 10
& "$root\summarize.ps1" -Sets H;& "$root\p99m.ps1" -Set H
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force
'GO_DONE'

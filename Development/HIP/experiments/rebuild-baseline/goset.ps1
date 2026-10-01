# goset.ps1 -Set X -Build b -CandHost h -RollHost hr [-CandAssets] [-Extra flags] [-SkipCorrect]: flat-X = build-<b>\gfx1201, 19 groups + 3 ABBA vs installed (base host + flat-A + assets-base)
param([string]$Set,[string]$Build,[string]$CandHost,[string]$RollHost,[switch]$CandAssets,[string[]]$Extra=@(),[switch]$SkipCorrect,[int]$Rounds=3)
$root='D:\DLSSNR-Lab\hip-backend\rebuild-baseline-20261001'
Remove-Item "$root\flat-$Set" -Recurse -Force -EA 0;New-Item -ItemType Directory "$root\flat-$Set"|Out-Null;Copy-Item "$root\build-$Build\gfx1201\*.hsaco" "$root\flat-$Set"
Get-ChildItem $root -Directory -Filter "runtime-regression-$Set-*"|Remove-Item -Recurse -Force
try{& "$root\full.ps1" -Set $Set -Rounds $Rounds -CandAssets:$CandAssets -Extra $Extra -SkipCorrect:$SkipCorrect -CandHost $CandHost -RollHost $RollHost *> "$root\full-$Set.log";'FULL OK'}catch{"FULL FAIL $_"}
"SAME-count: $((Select-String -Path "$root\full-$Set.log" -Pattern '^SAME|AE CSV SAME').Count)"
Get-Content "$root\full-$Set.log" | Select-String 'FAIL|changed|throw|Error|DIFF' | Select-Object -Last 10
& "$root\summarize.ps1" -Sets $Set;& "$root\p99m.ps1" -Set $Set
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force
'GOSET_DONE'

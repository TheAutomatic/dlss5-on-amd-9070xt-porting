# cand.ps1 -Set X [-Module m -Build name] [-CandAssets] [-Extra flags] : flat-X = flat-A (+ build-<Build>\gfx1201\<Module>), 19 groups + 3 ABBA, summary, clean dumps
param([string]$Set,[string]$Module="deep_fast-packed",[string]$Build="",[switch]$CandAssets,[string[]]$Extra=@(),[int]$Rounds=3,[switch]$SkipCorrect,[string]$CandHost="P",[string]$RollHost="Proll")
$root='D:\DLSSNR-Lab\hip-backend\bitexact-pm-20261001'
Get-ChildItem $root -Directory -Filter "runtime-regression-$Set-*"|Remove-Item -Recurse -Force
New-Item -ItemType Directory -Force "$root\flat-$Set"|Out-Null;Copy-Item "$root\flat-A\*.hsaco" "$root\flat-$Set" -Force
if($Build){foreach($m in $Module -split ','){Copy-Item "$root\build-$Build\gfx1201\$m.hsaco" "$root\flat-$Set" -Force}}
"flat-$Set "+((Get-ChildItem "$root\flat-$Set" -Filter 'deep_fast-packed.hsaco'|Get-FileHash).Hash.Substring(0,8))
try{& "$root\full.ps1" -Set $Set -Rounds $Rounds -CandAssets:$CandAssets -Extra $Extra -SkipCorrect:$SkipCorrect -CandHost $CandHost -RollHost $RollHost *> "$root\full-$Set.log";'FULL OK'}catch{"FULL FAIL $_"}
"SAME-count: $((Select-String -Path "$root\full-$Set.log" -Pattern '^SAME|AE CSV SAME').Count)"
Get-Content "$root\full-$Set.log" | Select-String 'FAIL|changed|throw|Error|DIFF' | Select-Object -Last 10
& "$root\summarize.ps1" -Sets $Set;& "$root\p99m.ps1" -Set $Set
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force

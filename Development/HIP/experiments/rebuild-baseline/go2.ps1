# go2.ps1: split the HEAD slowdown. HO = HEAD host + HEAD modules + installed assets; SO = installed host (base) + HEAD modules + HEAD shaders. timing only, 3 rounds
$root='D:\DLSSNR-Lab\hip-backend\rebuild-baseline-20261001'
foreach($s in 'HO','SO'){Remove-Item "$root\flat-$s" -Recurse -Force -EA 0;New-Item -ItemType Directory "$root\flat-$s"|Out-Null;Copy-Item "$root\flat-H\*.hsaco" "$root\flat-$s";Get-ChildItem $root -Directory -Filter "runtime-regression-$s-*"|Remove-Item -Recurse -Force}
& "$root\full.ps1" -Set HO -Rounds 3 -SkipCorrect -CandHost H *> "$root\full-HO.log"
& "$root\full.ps1" -Set SO -Rounds 3 -SkipCorrect -CandHost base -CandAssets *> "$root\full-SO.log"
& "$root\summarize.ps1" -Sets HO,SO;& "$root\p99m.ps1" -Set HO;& "$root\p99m.ps1" -Set SO
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force
'GO2_DONE'

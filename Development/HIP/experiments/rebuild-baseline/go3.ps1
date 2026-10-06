# go3.ps1: AA = installed host vs itself (harness bias), H0 = HEAD host with HIP_SP_INIT_PAIR=0; timing only, 3 rounds, HEAD modules
$root='D:\DLSSNR-Lab\hip-backend\rebuild-baseline-20261001'
foreach($s in 'AA','H0'){Remove-Item "$root\flat-$s" -Recurse -Force -EA 0;New-Item -ItemType Directory "$root\flat-$s"|Out-Null;Copy-Item "$root\flat-H\*.hsaco" "$root\flat-$s";Get-ChildItem $root -Directory -Filter "runtime-regression-$s-*"|Remove-Item -Recurse -Force}
& "$root\full.ps1" -Set AA -Rounds 3 -SkipCorrect -CandHost base *> "$root\full-AA.log"
& "$root\full.ps1" -Set H0 -Rounds 3 -SkipCorrect -CandHost H0 *> "$root\full-H0.log"
& "$root\summarize.ps1" -Sets AA,H0;& "$root\p99m.ps1" -Set AA;& "$root\p99m.ps1" -Set H0
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force
'GO3_DONE'

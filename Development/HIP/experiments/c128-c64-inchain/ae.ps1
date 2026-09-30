# correctness-only rerun (19 groups) of flat-<Set>, keeps AE CSVs for diffing
param([string]$Set)
$root='D:\DLSSNR-Lab\hip-backend\c128-c64-inchain-20261001'
Get-ChildItem $root -Directory -Filter "runtime-regression-$Set-*"|Remove-Item -Recurse -Force
try{& "$root\full.ps1" -Set $Set -Rounds 1 *> "$root\ae-$Set.log";'FULL OK'}catch{"FULL FAIL $_"}
"SAME-count: $((Select-String -Path "$root\ae-$Set.log" -Pattern '^SAME|AE CSV SAME').Count)"
foreach($slot in Get-ChildItem "$root\runtime-regression-$Set-adaptive" -Directory -Filter '*-True'){$b=$slot.FullName.Substring(0,$slot.FullName.Length-4)+'False';$x=Get-Content "$b\adaptive.csv";$y=Get-Content "$($slot.FullName)\adaptive.csv";$d=Compare-Object $x $y;"$($slot.Name) lines $($x.Count)/$($y.Count) diffs $(@($d).Count)";$d|Select-Object -First 4|Out-String}
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force

# mechanism check: candidate host = benchmark-reset0 (adaptive 500 ms idle reset forced on every frame), same modules; images vs AE CSV
$root='D:\DLSSNR-Lab\hip-backend\c128-c64-inchain-20261001'
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
Get-ChildItem $root -Directory -Filter 'runtime-regression-A-aereset'|Remove-Item -Recurse -Force
& "$root\regression.ps1" -Set A -Adaptive 1 -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-reset0.exe -CorrectnessOnly -Batch aereset *> "$root\ae-reset.log"
"images: $((Select-String -Path "$root\ae-reset.log" -Pattern '^SAME').Count) SAME; errors: $(@(Select-String -Path "$root\ae-reset.log" -Pattern 'differ|throw|DIFF').Count)"
Select-String -Path "$root\ae-reset.log" -Pattern 'differ|DIFF|Exception' | Select-Object -First 5 | ForEach-Object{$_.Line}
foreach($s in Get-ChildItem "$root\runtime-regression-A-aereset" -Directory -Filter '*-True'){$b=$s.FullName.Substring(0,$s.FullName.Length-4)+'False';$x=Get-Content "$b\adaptive.csv";$y=Get-Content "$($s.FullName)\adaptive.csv";$n=@(Compare-Object $x $y).Count;"$($s.Name) csvdiff=$n";if($n){"  base: $($x[3]) | $($x[4])";"  rst : $($y[3]) | $($y[4])"}}
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force

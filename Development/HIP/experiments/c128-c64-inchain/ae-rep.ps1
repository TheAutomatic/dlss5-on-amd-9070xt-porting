# AE determinism: N correctness-only adaptive runs of the installed set against itself (-SameSet), keep every adaptive.csv,
# report which cases/frames/columns differ from run 1. Optional -Cand <Set>: candidate slots use flat-<Set> (e.g. QF2).
param([int]$N=8,[string]$Cand='',[string]$Base='A')
$root='D:\DLSSNR-Lab\hip-backend\c128-c64-inchain-20261001'
& "$root\setup.ps1"|Out-Null
$t=Get-Content "$root\regression.ps1" -Raw;$t=$t.Replace('|^rtc_compile','');Set-Content "$root\regression.ps1" $t
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
$tag=if($Cand){"aec-$Cand"}else{'aer'}
$out="$root\ae-rep-$tag";Remove-Item $out -Recurse -Force -EA 0;New-Item -ItemType Directory $out|Out-Null
foreach($i in 1..$N){
 Get-ChildItem $root -Directory -Filter "runtime-regression-*-$tag*"|Remove-Item -Recurse -Force
 if($Cand){& "$root\regression.ps1" -Set $Cand -Adaptive 1 -BenchName benchmark-base.exe -Base $Base -CandidateBenchName benchmark-base.exe -CorrectnessOnly -Batch "$tag" *> "$out\run$i.log"}
 else{& "$root\regression.ps1" -Set A -Adaptive 1 -BenchName benchmark-base.exe -Base A -SameSet -CorrectnessOnly -Batch "$tag" *> "$out\run$i.log"}
 $ok=$?;$d=Get-ChildItem $root -Directory -Filter "runtime-regression-*-$tag"|Select-Object -First 1
 foreach($s in Get-ChildItem $d.FullName -Directory){Copy-Item "$($s.FullName)\adaptive.csv" "$out\$i-$($s.Name).csv"}
 "run $i ok=$ok images: $((Select-String -Path "$out\run$i.log" -Pattern '^SAME').Count) SAME"
}
$ref=@{};foreach($f in Get-ChildItem $out -Filter '1-*.csv'){$ref[$f.Name.Substring(2)]=Get-Content $f.FullName}
foreach($f in Get-ChildItem $out -Filter '*.csv'){$k=$f.Name.Substring($f.Name.IndexOf('-')+1);$x=$ref[$k];$y=Get-Content $f.FullName;for($j=0;$j -lt [Math]::Max($x.Count,$y.Count);$j++){if($x[$j] -ne $y[$j]){"DIFF $($f.Name) line $($j+1): ref '$($x[$j])' got '$($y[$j])'"}}}
# also False vs True within each run
foreach($i in 1..$N){foreach($f in Get-ChildItem $out -Filter "$i-*-True.csv"){$b=$f.FullName.Replace('-True.csv','-False.csv');if((Get-Content $b -Raw) -cne (Get-Content $f.FullName -Raw)){"PAIRDIFF $($f.Name)"}}}
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force
'AE_REP_DONE'

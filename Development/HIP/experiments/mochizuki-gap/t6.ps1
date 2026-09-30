# diagnostic ablations (wrong output, timing only, 1 ABBA round each) vs flat-CF, host P3
param([string[]]$Names=@('AB1','AB2'),[string]$Module='c512-m32-mh')
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001'
foreach($n in ($Names -split ',')){
 Remove-Item -Recurse -Force "$root\flat-$n","$root\runtime-regression-$n-*" -EA 0
 New-Item -ItemType Directory -Force "$root\flat-$n"|Out-Null;Copy-Item "$root\flat-CF\*" "$root\flat-$n";Copy-Item "$root\cand-$n\$Module.hsaco" "$root\flat-$n" -Force
 & "$root\regression.ps1" -Set $n -BenchName benchmark-P3.exe -Base CF -CandidateBenchName benchmark-P3.exe -TimingOnly -TimingFrames 1000 -Batch "timing-P3-1" *> "$root\t6-$n.log"
 & "$root\summarize.ps1" -Sets $n}

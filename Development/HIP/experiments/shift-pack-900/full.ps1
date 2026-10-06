param([switch]$SkipCorrect,[switch]$SkipTiming,[int]$Rounds=2)
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\shift-pack-900-20260930'
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
if(!$SkipCorrect){
foreach($cand in 'P','Pp'){foreach($ae in 0,1){
 $batch=if($ae){"adaptive-$cand"}else{"correct-$cand"}
 & "$root\regression.ps1" -Set P -Adaptive $ae -BenchName benchmark-base.exe -CandidateBenchName "benchmark-$cand.exe" -CorrectnessOnly -Batch $batch
 if(!$?){throw 'Full regression failed'}
}
foreach($slot in Get-ChildItem "$root\runtime-regression-P-adaptive-$cand" -Directory -Filter '*-True'){
 $base=$slot.FullName.Substring(0,$slot.FullName.Length-4)+'False'
 if([IO.File]::ReadAllText("$base\adaptive.csv") -cne [IO.File]::ReadAllText("$($slot.FullName)\adaptive.csv")){throw 'AE decisions changed'}
};"AE CSV SAME $cand"}
$env:SP_VALIDATE='1';$env:SP_TRACE='1';$env:SP_TICKET_LIMIT='1024';$env:SP_TICKET_START='4294967290'
foreach($cand in 'Proll','Pproll'){foreach($ae in 0,1){
 & "$root\regression.ps1" -Set P -Adaptive $ae -BenchName benchmark-base.exe -CandidateBenchName "benchmark-$cand.exe" -CorrectnessOnly -Only @('900-history','1080-history') -Batch "roll-$cand-$ae"
 if(!$?){throw 'Rollover regression failed'}
}}
$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
}
if(!$SkipTiming){foreach($round in 1..$Rounds){
 & "$root\regression.ps1" -Set P -BenchName benchmark-A.exe -CandidateBenchName benchmark-P.exe -TimingOnly -TimingFrames 1000 -Batch "timing$round"
 if(!$?){throw 'ABBA failed'}
}}
'FULL_DONE'

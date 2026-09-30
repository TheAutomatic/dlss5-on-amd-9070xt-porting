# 19 groups (7 cases x EXACT/AE + AE CSV + 900/1080 history rollover) + ABBA rounds; base = benchmark-base + flat-A, candidate = benchmark-P + flat-<Set>
param([string]$Set='S',[int]$Rounds=3,[switch]$SkipCorrect)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\swin-body-gap-20261001'
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
if(!$SkipCorrect){
 foreach($ae in 0,1){& "$root\regression.ps1" -Set $Set -Adaptive $ae -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-P.exe -CorrectnessOnly -Batch $(if($ae){'adaptive'}else{'correct'});if(!$?){throw 'regression failed'}}
 foreach($slot in Get-ChildItem "$root\runtime-regression-$Set-adaptive" -Directory -Filter '*-True'){$base=$slot.FullName.Substring(0,$slot.FullName.Length-4)+'False';if([IO.File]::ReadAllText("$base\adaptive.csv") -cne [IO.File]::ReadAllText("$($slot.FullName)\adaptive.csv")){throw 'AE decisions changed'}};"AE CSV SAME $Set"
 $env:SP_VALIDATE='1';$env:SP_TRACE='1';$env:SP_TICKET_LIMIT='1024';$env:SP_TICKET_START='4294967290'
 foreach($ae in 0,1){& "$root\regression.ps1" -Set $Set -Adaptive $ae -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-Proll.exe -CorrectnessOnly -Only @('900-history','1080-history') -Batch "roll-$ae";if(!$?){throw 'rollover failed'}}
 $env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'}
foreach($round in 1..$Rounds){& "$root\regression.ps1" -Set $Set -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-P.exe -TimingOnly -TimingFrames 1000 -Batch "timing-$round";if(!$?){throw 'ABBA failed'}}
"FULL_DONE $Set"

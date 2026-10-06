# 19 groups + ABBA rounds. base = benchmark-base + flat-A + assets-base; candidate = benchmark-P (+Proll for rollover) + flat-<Set> [+ assets-cand] [+ extra flags]
param([string]$Set,[int]$Rounds=3,[switch]$CandAssets,[string[]]$Extra=@(),[switch]$SkipCorrect,[switch]$SkipTiming,[string]$CandHost="P",[string]$RollHost="Proll")
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\bitexact-pm-20261001'
$ca=if($CandAssets){'D:\DLSSNR-Lab\hip-backend\bitexact-pm-20261001\assets-cand'}else{''}
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
if(!$SkipCorrect){
 foreach($ae in 0,1){& "$root\regression.ps1" -Set $Set -Adaptive $ae -BenchName benchmark-base.exe -Base A -CandidateBenchName "benchmark-$CandHost.exe" -CandidateAssets $ca -CandidateExtra $Extra -CorrectnessOnly -Batch $(if($ae){'adaptive'}else{'correct'});if(!$?){throw 'regression failed'}}
 foreach($slot in Get-ChildItem "$root\runtime-regression-$Set-adaptive" -Directory -Filter '*-True'){$base=$slot.FullName.Substring(0,$slot.FullName.Length-4)+'False';if([IO.File]::ReadAllText("$base\adaptive.csv") -cne [IO.File]::ReadAllText("$($slot.FullName)\adaptive.csv")){throw 'AE decisions changed'}};"AE CSV SAME $Set"
 $env:SP_VALIDATE='1';$env:SP_TRACE='1';$env:SP_TICKET_LIMIT='1024';$env:SP_TICKET_START='4294967290'
 foreach($ae in 0,1){& "$root\regression.ps1" -Set $Set -Adaptive $ae -BenchName benchmark-base.exe -Base A -CandidateBenchName "benchmark-$RollHost.exe" -CandidateAssets $ca -CandidateExtra $Extra -CorrectnessOnly -Only @('900-history','1080-history') -Batch "roll-$ae";if(!$?){throw 'rollover failed'}}
 $env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'}
if(!$SkipTiming){foreach($round in 1..$Rounds){& "$root\regression.ps1" -Set $Set -BenchName benchmark-base.exe -Base A -CandidateBenchName "benchmark-$CandHost.exe" -CandidateAssets $ca -CandidateExtra $Extra -TimingOnly -TimingFrames 1000 -Batch "timing-$round";if(!$?){throw 'ABBA failed'}}}
"FULL_DONE $Set"

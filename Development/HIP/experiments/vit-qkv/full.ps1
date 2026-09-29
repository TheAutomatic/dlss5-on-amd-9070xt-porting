param([switch]$SkipCorrect,[switch]$SkipTiming,[string]$Module="build-w5",[int]$Rounds=2,[string]$Tag="")
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\vit-qkv-20260929'
# Candidate = hostP (benchmark-P.exe: w5 launch when the module exports it) + flat-P (vit-stream with HIP_VIT_QKV_W5 1).
Copy-Item "$root\$Module\gfx1201\vit-stream.hsaco" "$root\flat-P\vit-stream.hsaco" -Force
"flat-P vit-stream $((Get-FileHash "$root\flat-P\vit-stream.hsaco").Hash)"
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
if(!$SkipCorrect){
foreach($ae in 0,1){
 $batch=if($ae){'adaptive'}else{'correct'}
 & "$root\regression.ps1" -Set P -Adaptive $ae -BenchName benchmark-base.exe -CandidateBenchName benchmark-P.exe -CorrectnessOnly -Batch "$batch$Tag"
 if(!$?){throw 'Full regression failed'}
}
foreach($slot in Get-ChildItem "$root\runtime-regression-P-adaptive$Tag" -Directory -Filter '*-True'){
 $base=$slot.FullName.Substring(0,$slot.FullName.Length-4)+'False'
 if([IO.File]::ReadAllText("$base\adaptive.csv") -cne [IO.File]::ReadAllText("$($slot.FullName)\adaptive.csv")){throw 'AE decisions changed'}
}
$env:SP_VALIDATE='1';$env:SP_TRACE='1';$env:SP_TICKET_LIMIT='1024';$env:SP_TICKET_START='4294967290'
foreach($ae in 0,1){
 & "$root\regression.ps1" -Set P -Adaptive $ae -BenchName benchmark-base.exe -CandidateBenchName benchmark-Proll.exe -CorrectnessOnly -Only @('900-history','1080-history') -Batch "roll-$ae$Tag"
 if(!$?){throw 'Rollover regression failed'}
}
$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
}
if(!$SkipTiming){
foreach($round in 1..$Rounds){
 & "$root\regression.ps1" -Set P -BenchName benchmark-A.exe -CandidateBenchName benchmark-P.exe -TimingOnly -TimingFrames 1000 -Batch "timing$round$Tag"
 if(!$?){throw 'ABBA failed'}
}}

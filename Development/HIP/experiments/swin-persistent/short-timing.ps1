param([string]$Prefix='async')
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929'
$env:SP_CHANNELS='4';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_FORCE_TIMEOUT='0'
$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
foreach($side in 1,2,3){
 $env:SP_SIDES="$side"
 & "$root\regression.ps1" -Set P -BenchName benchmark-base.exe -CandidateBenchName benchmark-sp.exe -TimingOnly -TimingFrames 240 -Batch "$Prefix-side$side"
 if(!$?){throw 'Short timing failed'}
}

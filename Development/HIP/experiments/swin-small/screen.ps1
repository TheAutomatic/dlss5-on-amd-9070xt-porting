param([int]$Channel=2,[int]$Side=1)
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-small-20260929'
$tag="c$Channel-s$Side"
$env:SP_SMALL_CHANNELS="$Channel";$env:SP_SMALL_SIDES="$Side"
$env:SP_VALIDATE='1';$env:SP_TRACE='1';$env:SP_FORCE_TIMEOUT='0'
$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
foreach($adaptive in 0,1){
 & "$root\regression.ps1" -Set P -Adaptive $adaptive -BenchName benchmark-base.exe -CandidateBenchName benchmark-small.exe -CorrectnessOnly -Batch "$tag-a$adaptive"
 if(!$?){throw 'Exact regression failed'}
}
foreach($slot in Get-ChildItem "$root\runtime-regression-P-$tag-a1" -Directory -Filter '*-True'){
 $base=$slot.FullName.Substring(0,$slot.FullName.Length-4)+'False'
 if(Compare-Object (Get-Content "$base\adaptive.csv") (Get-Content "$($slot.FullName)\adaptive.csv")){throw 'AE decisions differ'}
}
$env:SP_VALIDATE='0';$env:SP_TRACE='0'
& "$root\regression.ps1" -Set P -BenchName benchmark-base.exe -CandidateBenchName benchmark-small.exe -TimingOnly -TimingFrames 240 -Batch "$tag-short"
if(!$?){throw 'Timing failed'}

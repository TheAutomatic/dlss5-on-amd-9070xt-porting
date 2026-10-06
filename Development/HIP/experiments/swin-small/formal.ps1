param([int]$Round=1,[switch]$ProductionBaseline)
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-small-20260929'
$driver=if($ProductionBaseline){'regression.ps1'}else{'regression-matched.ps1'}
$baseline=if($ProductionBaseline){'benchmark-base.exe'}else{'benchmark-small.exe'}
$label=if($ProductionBaseline){'timing'}else{'matched'}
$env:SP_VALIDATE='0' ;$env:SP_TRACE='0';$env:SP_FORCE_TIMEOUT='0'
$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
foreach($pair in @(@(2,1),@(2,2),@(1,1),@(1,2))){
 $env:SP_SMALL_CHANNELS="$($pair[0])";$env:SP_REQUEST_CHANNELS="$($pair[0])";$env:SP_SMALL_SIDES="$($pair[1])"
 & "$root\$driver" -Set P -BenchName $baseline -CandidateBenchName benchmark-small.exe -TimingOnly -TimingFrames 1000 -Batch "c$($pair[0])-s$($pair[1])-$label$Round"
 if(!$?){throw 'Formal timing failed'}
}

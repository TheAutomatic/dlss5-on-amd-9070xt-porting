$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929'
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_VALIDATE='1';$env:SP_TRACE='0';$env:SP_FORCE_TIMEOUT='0'
$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
foreach($adaptive in 0,1){
 $batch=if($adaptive){'adaptive'}else{'correct'}
 & "$root\regression.ps1" -Set P -Adaptive $adaptive -BenchName benchmark-base.exe -CandidateBenchName benchmark-sp.exe -CorrectnessOnly -Batch $batch
 if(!$?){throw 'Formal regression failed'}
}
$env:SP_VALIDATE='0'
foreach($batch in 'timing1','timing2'){
 & "$root\regression.ps1" -Set P -BenchName benchmark-base.exe -CandidateBenchName benchmark-sp.exe -TimingOnly -TimingFrames 1000 -Batch $batch
 if(!$?){throw 'Formal timing failed'}
}

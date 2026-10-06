$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929'
New-Item -ItemType Directory -Force "$root\flat-Q"|Out-Null
Copy-Item "$root\flat-A\*.hsaco" "$root\flat-Q" -Force
Copy-Item "$root\production\gfx1201\swin-persistent.hsaco" "$root\flat-Q" -Force
$env:SP_CHANNELS='0';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0'
foreach($adaptive in 0,1){
 $batch=if($adaptive){'adaptive'}else{'correct'}
 & "$root\regression-production.ps1" -Set Q -Adaptive $adaptive -BenchName benchmark-base.exe -CandidateBenchName benchmark-production.exe -CorrectnessOnly -Batch $batch
 if(!$?){throw 'Production regression failed'}
}
& "$root\regression-production.ps1" -Set Q -SwinRun 0 -BenchName benchmark-base.exe -CandidateBenchName benchmark-production.exe -CorrectnessOnly -Only @('900-motion') -Batch off
if(!$?){throw 'Disabled path failed'}
& "$root\regression-production.ps1" -Set Q -SameSet -Base A -BenchName benchmark-production.exe -CorrectnessOnly -Only @('900-motion') -Batch missing
if(!$?){throw 'Missing module fallback failed'}
foreach($batch in 'timing1','timing2'){
 & "$root\regression-production.ps1" -Set Q -BenchName benchmark-base.exe -CandidateBenchName benchmark-production.exe -TimingOnly -TimingFrames 1000 -Batch $batch
 if(!$?){throw 'Production timing failed'}
}

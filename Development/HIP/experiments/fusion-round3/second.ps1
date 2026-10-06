$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\fusion-round3'
& "$r\regression.ps1" -Set D -Batch screen -CorrectnessOnly -Only 1080-motion -CandidateBenchName benchmark-D.exe
if($LASTEXITCODE){throw 'D correctness'}
foreach($set in 'D','U','T'){
 $batch=if($set -eq 'D'){'screen1'}else{'screen2'}
 & "$r\regression.ps1" -Set $set -Batch $batch -TimingOnly -TimingFrames 200 -CandidateBenchName "benchmark-$set.exe"
 if($LASTEXITCODE){throw 'timing'}
}

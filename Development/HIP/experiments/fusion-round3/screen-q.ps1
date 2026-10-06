$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\fusion-round3'
foreach($set in 'Q','R'){
 & "$r\regression.ps1" -Set $set -Batch screen -CorrectnessOnly -Only 1080-motion -CandidateBenchName "benchmark-$set.exe"
 if($LASTEXITCODE){throw 'correctness'}
 & "$r\regression.ps1" -Set $set -Batch screen1 -TimingOnly -TimingFrames 200 -CandidateBenchName "benchmark-$set.exe"
 if($LASTEXITCODE){throw 'timing'}
}

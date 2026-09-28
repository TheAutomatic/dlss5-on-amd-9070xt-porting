$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\daniel-kernels'
foreach($set in 'Q','R','C'){
 & "$r\regression.ps1" -Set $set -Batch screen-correct -CorrectnessOnly -Only 1080-motion
 if($LASTEXITCODE){throw 'screen correctness'}
}
foreach($round in 'screen1','screen2'){
 foreach($set in 'Q','R','C'){
  & "$r\regression.ps1" -Set $set -Batch $round -TimingOnly -TimingFrames 200
  if($LASTEXITCODE){throw 'screen timing'}
 }
}

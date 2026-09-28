$ErrorActionPreference='Stop'
$r='D:\DLSSNR-Lab\hip-backend\fma-vs-nvidia'
foreach($set in 'F','H'){
 & "$r\regression.ps1" -Set $set -CorrectnessOnly -Batch correct
 if($LASTEXITCODE){throw 'correctness'}
}
foreach($round in 'r1','r2'){foreach($set in 'F','H'){
 & "$r\regression.ps1" -Set $set -TimingOnly -Batch $round
 if($LASTEXITCODE){throw 'timing'}
}}

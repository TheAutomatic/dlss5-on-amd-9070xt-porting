$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\fusion-round3'
& "$r\regression.ps1" -Set U2 -Batch screen -CorrectnessOnly -Only 1080-motion -CandidateBenchName benchmark-U.exe
if($LASTEXITCODE){throw 'U2 correctness'}
foreach($batch in 'screen1','screen2'){
 & "$r\regression.ps1" -Set U2 -Batch $batch -TimingOnly -TimingFrames 200 -CandidateBenchName benchmark-U.exe
 if($LASTEXITCODE){throw 'U2 timing'}
}
foreach($mode in 0,1){
 $batch=if($mode){'adaptive'}else{'exact'}
 & "$r\regression.ps1" -Set C -Batch $batch -Adaptive $mode -CorrectnessOnly -CandidateBenchName benchmark-production.exe
 if($LASTEXITCODE){throw 'regression'}
}
foreach($batch in 'long1','long2'){
 & "$r\regression.ps1" -Set C -Batch $batch -TimingOnly -CandidateBenchName benchmark-production.exe
 if($LASTEXITCODE){throw 'timing'}
}
& "$r\cumulative.ps1"
if($LASTEXITCODE){throw 'cumulative'}

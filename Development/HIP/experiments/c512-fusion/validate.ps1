$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c512-fusion'
foreach($mode in 0,1){
 $batch=if($mode){'adaptive'}else{'exact'}
 & "$r\regression.ps1" -Set C -Batch $batch -Adaptive $mode -CorrectnessOnly -CandidateBenchName benchmark-production.exe
 if($LASTEXITCODE){throw 'regression'}
}
foreach($round in 'long1','long2'){
 & "$r\regression.ps1" -Set C -Batch $round -TimingOnly -CandidateBenchName benchmark-production.exe
 if($LASTEXITCODE){throw 'timing'}
}

param([string]$Set='B')
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c256-fusion'
foreach($mode in 0,1){
 $batch=if($mode){'adaptive'}else{'exact'}
 & "$r\regression.ps1" -Set $Set -Batch $batch -Adaptive $mode -CorrectnessOnly -CandidateBenchName benchmark-tier.exe
 if($LASTEXITCODE){throw 'regression'}
}
foreach($round in 'long1','long2'){
 & "$r\regression.ps1" -Set $Set -Batch $round -TimingOnly -CandidateBenchName benchmark-tier.exe
 if($LASTEXITCODE){throw 'timing'}
}

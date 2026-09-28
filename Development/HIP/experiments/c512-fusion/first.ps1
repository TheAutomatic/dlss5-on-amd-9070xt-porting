$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c512-fusion'
foreach($mode in 0,1){
 $batch=if($mode){'adaptive'}else{'exact'}
 & "$r\regression.ps1" -Set F -Batch $batch -Adaptive $mode -CorrectnessOnly
 if($LASTEXITCODE){throw 'regression'}
}
& "$r\build-other.ps1"
if($LASTEXITCODE){throw 'build candidates'}

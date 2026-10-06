$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\deep-layers'
foreach($mode in 0,1){
 $batch=if($mode){'adaptive'}else{'exact'}
 & "$r\regression.ps1" -Set P -Batch $batch -Adaptive $mode -CorrectnessOnly -CandidateBenchName benchmark-production.exe
 if($LASTEXITCODE){throw 'production regression'}
}
& "$r\collect-all.ps1"

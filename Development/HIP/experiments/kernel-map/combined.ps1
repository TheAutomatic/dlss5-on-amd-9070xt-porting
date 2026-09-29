$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\kernel-map'
& "$r\run-jobs.ps1" -List after-list.txt -Batch final-map
if($LASTEXITCODE){throw 'after microbench'}
foreach($mode in 0,1){$batch=if($mode){'adaptive'}else{'exact'};& "$r\regression.ps1" -Set C -Batch $batch -Adaptive $mode -CorrectnessOnly -CandidateBenchName benchmark-H.exe;if($LASTEXITCODE){throw 'combined regression'}}
& "$r\regression.ps1" -Set C -Batch abba1 -TimingOnly -CandidateBenchName benchmark-H.exe
if($LASTEXITCODE){throw 'combined ABBA'}

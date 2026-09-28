$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\daniel-kernels'
& "$r\regression.ps1" -Set P -Batch direct-correct -CorrectnessOnly -Only 900-motion,1080-motion
if($LASTEXITCODE){throw 'direct-io output'}
foreach($batch in 'r1','r2'){
 & "$r\regression.ps1" -Set P -Batch $batch -TimingOnly
 if($LASTEXITCODE){throw 'P retest'}
 & "$r\regression.ps1" -Set C -Batch "direct-$batch" -TimingOnly -TimingFrames 200
 if($LASTEXITCODE){throw 'C direct-io screen'}
}

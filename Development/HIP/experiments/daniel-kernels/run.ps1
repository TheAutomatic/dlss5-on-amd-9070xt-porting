$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\daniel-kernels'
& "$r\regression.ps1" -Set P -Batch correct -CorrectnessOnly
if($LASTEXITCODE){throw 'EXACT'}
& "$r\regression.ps1" -Set P -Batch adaptive -CorrectnessOnly -Adaptive 1
if($LASTEXITCODE){throw 'AE'}
foreach($round in 'r1','r2'){
 & "$r\regression.ps1" -Set P -Batch $round -TimingOnly
 if($LASTEXITCODE){throw 'timing'}
}

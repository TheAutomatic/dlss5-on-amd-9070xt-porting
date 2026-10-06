param([string[]]$Sets=@('O','L','B','F','BL'))
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c256-fusion'
foreach($s in $Sets){
 & "$r\regression.ps1" -Set $s -Batch screen -CorrectnessOnly -Only 1080-motion
 if($LASTEXITCODE){throw 'correctness'}
 & "$r\regression.ps1" -Set $s -Batch screen1 -TimingOnly -TimingFrames 200
 if($LASTEXITCODE){throw 'screen'}
}

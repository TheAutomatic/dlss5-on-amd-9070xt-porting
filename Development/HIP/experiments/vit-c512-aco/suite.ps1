param([string[]]$Sets=@('V'))
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\vit-c512-aco'
foreach($set in $Sets){
 try {
  & "$r\regression.ps1" -Set $set -Batch correct -CorrectnessOnly *> "$r\correct-$set.log"
  if($LASTEXITCODE){throw "regression failed $set"}
 } catch { "REJECT $set $_"|Add-Content "$r\suite-status.txt";continue }
 foreach($batch in 'r1','r2'){
  & "$r\regression.ps1" -Set $set -Batch $batch -TimingOnly *> "$r\timing-$set-$batch.log"
  if($LASTEXITCODE){throw "timing failed $set $batch"}
 }
 "PASS $set"|Add-Content "$r\suite-status.txt"
}
& "$r\regression.ps1" -Set V -Adaptive 1 -Batch adaptive -CorrectnessOnly *> "$r\adaptive-V.log"
if($LASTEXITCODE){throw 'adaptive regression'}
'SUITE_DONE'

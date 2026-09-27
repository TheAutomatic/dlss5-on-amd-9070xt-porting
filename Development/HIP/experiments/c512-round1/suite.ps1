param([string[]]$Sets=@('R','Q','N','L'))
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c512-round1'
foreach($set in $Sets){
 $bench=if($set -eq 'N'){'benchmark-n.exe'}else{'benchmark.exe'}
 try {
  & "$r\regression.ps1" -Set $set -BenchName $bench -Batch correct -CorrectnessOnly *> "$r\correct-$set.log"
  if($LASTEXITCODE){throw "regression failed $set"}
 } catch { "REJECT $set $_"|Add-Content "$r\suite-status.txt";continue }
 & "$r\regression.ps1" -Set $set -BenchName $bench -Adaptive 1 -Batch adaptive -CorrectnessOnly *> "$r\adaptive-$set.log"
 foreach($batch in 'r1','r2'){
  & "$r\regression.ps1" -Set $set -BenchName $bench -Batch $batch -TimingOnly *> "$r\timing-$set-$batch.log"
  if($LASTEXITCODE){throw "timing failed $set $batch"}
 }
 "PASS $set"|Add-Content "$r\suite-status.txt"
}
'SUITE_DONE'

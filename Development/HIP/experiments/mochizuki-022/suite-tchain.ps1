param([string[]]$Sets=@('S','V'))
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mochizuki-022'
foreach($set in $Sets){
 & "$r\regression.ps1" -Set $set -BenchName benchmark-tc.exe -Batch correct -CorrectnessOnly *> "$r\correct-$set.log"
 if($LASTEXITCODE){throw "TC correctness $set"}
 & "$r\regression.ps1" -Set $set -BenchName benchmark-tc.exe -Adaptive 1 -Batch adaptive -CorrectnessOnly *> "$r\adaptive-$set.log"
 if($LASTEXITCODE){throw "TC adaptive $set"}
 & "$r\regression.ps1" -Set $set -BenchName benchmark-wrap.exe -Only 900-history,1080-history -Batch wrap -CorrectnessOnly *> "$r\wrap-$set.log"
 if($LASTEXITCODE){throw "TC wrap $set"}
 foreach($batch in 'r1','r2'){
  & "$r\regression.ps1" -Set $set -BenchName benchmark-tc.exe -Batch $batch -TimingOnly *> "$r\timing-$set-$batch.log"
  if($LASTEXITCODE){throw "TC timing $set"}
 }
 "PASS $set"|Add-Content "$r\suite-status.txt"
}
'TCHAIN_SUITE_DONE'

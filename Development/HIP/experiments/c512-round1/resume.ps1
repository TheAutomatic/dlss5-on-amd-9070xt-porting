# Resume verified checkpoints; never benchmark alongside a game.
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c512-round1'
function Idle {if(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^benchmark|^ledger$'}){throw 'GPU busy'}}
function Seven($file){(Test-Path $file) -and @((Get-Content $file)|Where-Object {$_ -like 'SAME *'}).Count -eq 7}
Idle
if(!(Test-Path "$r\1080-pdl1\run.log") -or !(Select-String -Path "$r\1080-pdl1\run.log" -Pattern 'PASS c512 ledger' -Quiet)){
 if(Test-Path "$r\1080-pdl1"){Move-Item "$r\1080-pdl1" "$r\rejected-1080-$(Get-Date -Format yyyyMMdd-HHmmss)"}
 & "$r\ledger.ps1" -Heights 1080
 if($LASTEXITCODE){throw 'Ledger failed'}
}
foreach($set in 'R','Q','N','L'){
 $bench=if($set -eq 'N'){'benchmark-n.exe'}else{'benchmark.exe'}
 if(!(Seven "$r\correct-$set.log")){
  & "$r\regression.ps1" -Set $set -BenchName $bench -Batch correct -CorrectnessOnly *> "$r\correct-$set.log"
  if(!(Seven "$r\correct-$set.log")){throw "Correctness incomplete $set"}
 }
 if(!(Seven "$r\adaptive-$set.log")){
  & "$r\regression.ps1" -Set $set -BenchName $bench -Adaptive 1 -Batch adaptive -CorrectnessOnly *> "$r\adaptive-$set.log"
  if(!(Seven "$r\adaptive-$set.log")){throw "Adaptive correctness incomplete $set"}
 }
 foreach($batch in 'r1','r2'){
  Idle;$log="$r\timing-$set-$batch.log";$done=0
  if(Test-Path $log){$done=@(Get-Content $log|Where-Object {$_ -like '*"tag":"time-*'}).Count}
  if($done -eq 8){continue}
  $dir="$r\runtime-regression-$set-$batch"
  if(Test-Path $dir){$stamp=Get-Date -Format yyyyMMdd-HHmmss;Move-Item $dir "$r\rejected-$set-$batch-$stamp";if(Test-Path $log){Move-Item $log "$r\rejected-$set-$batch-$stamp.log"}}
  & "$r\regression.ps1" -Set $set -BenchName $bench -Batch $batch -TimingOnly *> $log
  if($LASTEXITCODE){throw "Timing failed $set $batch"}
 }
 "PASS $set"|Add-Content "$r\suite-status.txt"
}
Idle
& "$r\resources.exe" $r "$r\resources.csv" > "$r\resources-result.txt"
if($LASTEXITCODE){throw 'Resources query failed'}
& "$r\tail.ps1"
if($LASTEXITCODE){throw 'Tail ledger failed'}
& "$r\collect.ps1"
& "$r\collect-adaptive.ps1"
'ROUND6_SUITE_DONE'

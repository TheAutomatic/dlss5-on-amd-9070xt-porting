$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mochizuki-022'
& "$r\regression.ps1" -Set H -BenchName benchmark-group.exe -Batch correct -CorrectnessOnly *> "$r\correct-H.log"
if($LASTEXITCODE){throw 'WG4 correctness'}
& "$r\regression.ps1" -Set H -BenchName benchmark-group.exe -Adaptive 1 -Batch adaptive -CorrectnessOnly *> "$r\adaptive-H.log"
if($LASTEXITCODE){throw 'WG4 adaptive'}
foreach($b in 'correct','adaptive'){
 foreach($d in Get-ChildItem "$r\runtime-regression-H-$b" -Directory|Where-Object {$_.Name -like '*True'}){
  if(!(Select-String -Path "$($d.FullName)\run.log" -Pattern '^WG4 calls=156$' -Quiet)){throw 'WG4 did not replace 13 kernels/frame'}
 }
}
foreach($batch in 'r1','r2'){
 & "$r\regression.ps1" -Set H -BenchName benchmark-group.exe -Batch $batch -TimingOnly *> "$r\timing-H-$batch.log"
 if($LASTEXITCODE){throw 'WG4 timing'}
}
'PASS H'|Add-Content "$r\suite-status.txt"
'WG4_SUITE_DONE'

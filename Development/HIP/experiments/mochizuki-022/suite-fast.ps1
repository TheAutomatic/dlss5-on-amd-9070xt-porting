$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mochizuki-022'
& "$r\regression.ps1" -Set F -BenchName benchmark-fast.exe -Batch correct -CorrectnessOnly *> "$r\correct-F.log"
if($LASTEXITCODE){throw 'F correctness'}
& "$r\regression.ps1" -Set F -BenchName benchmark-fast.exe -Adaptive 1 -Batch adaptive -CorrectnessOnly *> "$r\adaptive-F.log"
if($LASTEXITCODE){throw 'F adaptive'}
& "$r\regression.ps1" -Set F -BenchName benchmark-fast-wrap.exe -Only 900-history,1080-history -Batch wrap -CorrectnessOnly *> "$r\wrap-F.log"
if($LASTEXITCODE){throw 'F wrap'}
& "$r\regression.ps1" -Set F -BenchName benchmark-fast-wrap.exe -Adaptive 1 -Only 900-static,1080-static -Batch wrapae -CorrectnessOnly *> "$r\wrapae-F.log"
if($LASTEXITCODE){throw 'F adaptive wrap'}
foreach($batch in 'r1','r2'){
 & "$r\regression.ps1" -Set F -BenchName benchmark-fast.exe -Batch $batch -TimingOnly *> "$r\timing-F-$batch.log"
 if($LASTEXITCODE){throw 'F timing'}
}
'PASS F'|Add-Content "$r\suite-status.txt"
'FAST_SUITE_DONE'

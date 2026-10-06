$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mochizuki-022'
foreach($set in @('S')){
 & "$r\regression.ps1" -Set $set -BenchName benchmark-wrap.exe -Adaptive 1 -Only 900-static,1080-static -Batch wrapae -CorrectnessOnly *> "$r\wrapae-$set.log"
 if($LASTEXITCODE){throw "AE wrap $set"}
}
& "$r\trace-tchain.ps1"
& "$r\collect.ps1"
& "$r\collect-adaptive.ps1"
'FINISH_CHECKS_DONE'

$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\vit-bytestream'
foreach($batch in 'ae-r1','ae-r2'){
 & "$r\regression.ps1" -Set V3 -Adaptive 1 -TimingSequence 1 -Batch $batch -TimingOnly *> "$r\timing-V3-$batch.log"
}
& "$r\runtime-check.ps1"
& 'D:\DLSSNR-Lab\hip-backend\c512-mix\suite.ps1'
'FINAL_CHECKS_DONE'

# Fallback correctness: F1 = new host + installed modules; F2 = base host + G modules.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\gap-fusion-20260930'
try{& "$root\full.ps1" -Set A -Cand P -RollHost Proll -SkipTiming *> "$root\full-F1.log";'F1 OK'}catch{"F1 FAIL $_"}
try{& "$root\full.ps1" -Set G -Cand base -RollHost base -SkipTiming *> "$root\full-F2.log";'F2 OK'}catch{"F2 FAIL $_"}
'FB_DONE'

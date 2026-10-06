# W = new host (benchmark-P) + W16 modules; F1 = new host + installed modules (fallback, correctness only); F2 = old host + W16 modules (correctness only).
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\c256-w16-20260930'
& "$root\mkset.ps1" -Name W -Builds Wc64,Wsp
try{& "$root\full.ps1" -Set W -Cand P -RollHost Proll *> "$root\full-W.log";'W OK'}catch{"W FAIL $_"|Tee-Object -Append "$root\full-W.log"}
try{& "$root\full.ps1" -Set A -Cand P -RollHost Proll -SkipTiming *> "$root\full-F1.log";'F1 OK'}catch{"F1 FAIL $_"|Tee-Object -Append "$root\full-F1.log"}
try{& "$root\full.ps1" -Set W -Cand base -RollHost base -SkipTiming *> "$root\full-F2.log";'F2 OK'}catch{"F2 FAIL $_"|Tee-Object -Append "$root\full-F2.log"}
& "$root\summarize.ps1" -Sets W
'RUN_DONE'

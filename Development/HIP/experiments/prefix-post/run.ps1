# prod = recipe (must equal installed c32-wave1 .text/.rodata), X = CW_PREPOST_BYTE 1 (adds the four byte exports only).
# X = new host + X module (bit-exact + 3 ABBA rounds); F1 = new host + installed modules (fallback); F2 = old host + X module;
# split timing Ppre/Ppost (one round each); per-kernel jobbench (jobs.ps1).
param([switch]$NoBuild)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\prefix-post-20260930'
if(!$NoBuild){& "$root\build.ps1" -Name prod -Module c32-wave1;& "$root\build.ps1" -Name X -Module c32-wave1 -Defs 'CW_PREPOST_BYTE 1';& "$root\mkset.ps1" -Name X -Builds X}
try{& "$root\full.ps1" -Set X -Cand P -RollHost Proll -Rounds 3 *> "$root\full-X.log";'X OK'}catch{"X FAIL $_"|Tee-Object -Append "$root\full-X.log"}
try{& "$root\full.ps1" -Set A -Cand P -RollHost Proll -SkipTiming *> "$root\full-F1.log";'F1 OK'}catch{"F1 FAIL $_"|Tee-Object -Append "$root\full-F1.log"}
try{& "$root\full.ps1" -Set X -Cand base -RollHost base -SkipTiming *> "$root\full-F2.log";'F2 OK'}catch{"F2 FAIL $_"|Tee-Object -Append "$root\full-F2.log"}
foreach($c in 'Ppre','Ppost'){try{& "$root\full.ps1" -Set X -Cand $c -SkipCorrect -Rounds 1 *> "$root\full-$c.log";"$c OK"}catch{"$c FAIL $_"}}
& "$root\summarize.ps1" -Sets X
try{& "$root\jobs.ps1" *> "$root\jobs.log";'JOBS OK'}catch{"JOBS FAIL $_"}
'RUN_DONE'

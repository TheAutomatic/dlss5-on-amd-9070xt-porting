# W64 / W128 = new host (benchmark-P) + c64-wave2 with only the C64 / C128 _w16 exports: bit-exact (19 groups) + 3 ABBA rounds each.
# W3 (both) correctness; F1 = new host + installed modules, F2 = installed-source host + W3 modules, H = origin/main host (7b821c7f, latest add-on source without this patch) + installed modules.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\w16-c64-c128-20260930'
foreach($s in 'W64','W128','W3'){& "$root\mkset.ps1" -Name $s -Builds $s}
foreach($s in 'W64','W128'){try{& "$root\full.ps1" -Set $s -Cand P -RollHost P -Rounds 3 *> "$root\full-$s.log";"$s OK"}catch{"$s FAIL $_"|Tee-Object -Append "$root\full-$s.log"}}
try{& "$root\full.ps1" -Set W3 -Cand Pdiag -RollHost P -SkipTiming *> "$root\full-W3.log";'W3 OK'}catch{"W3 FAIL $_"|Tee-Object -Append "$root\full-W3.log"}
try{& "$root\full.ps1" -Set A -Cand P -RollHost P -SkipTiming *> "$root\full-F1.log";'F1 OK'}catch{"F1 FAIL $_"|Tee-Object -Append "$root\full-F1.log"}
try{& "$root\full.ps1" -Set W3 -Cand base -RollHost base -SkipTiming *> "$root\full-F2.log";'F2 OK'}catch{"F2 FAIL $_"|Tee-Object -Append "$root\full-F2.log"}
try{& "$root\full.ps1" -Set A -Cand H -RollHost H -SkipTiming *> "$root\full-H.log";'H OK'}catch{"H FAIL $_"|Tee-Object -Append "$root\full-H.log"}
& "$root\summarize.ps1" -Sets W64,W128
'RUN_DONE'

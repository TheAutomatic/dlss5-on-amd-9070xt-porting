# F1 rerun (new host + installed modules, correctness), recipe build, RE9 runtime check, install.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\prefix-post-20260930'
Remove-Item -Recurse -Force "$root\runtime-regression-A-*" -ErrorAction SilentlyContinue
try{& "$root\full.ps1" -Set A -Cand P -RollHost Proll -SkipTiming *> "$root\full-F1b.log";'F1b OK'}catch{"F1b FAIL $_";exit 1}
& "$root\final.ps1"
& "$root\runtime-check.ps1"
& "$root\install.ps1"
'FINISH_DONE'

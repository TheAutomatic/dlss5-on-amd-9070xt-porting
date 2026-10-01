# PK re-time: 3 more ABBA rounds (timing only) as batch PK2 (same flat-PK, host P3, assets-cand, IO_FUSE=1)
$root='D:\DLSSNR-Lab\hip-backend\bitexact-pm-20261001'
New-Item -ItemType Directory -Force "$root\flat-PK2"|Out-Null;Copy-Item "$root\flat-PK\*.hsaco" "$root\flat-PK2" -Force
& "$root\cand.ps1" -Set PK2 -Build final -CandAssets -Extra @('DLSS5_IO_FUSE=1') -CandHost P3 -RollHost P3roll -SkipCorrect
'GO3_DONE'

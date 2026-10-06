# pending-review-20261003 runner: full 19-group correctness + 3 ABBA rounds for one candidate set.
param([string]$Set,[switch]$CandAssets,[string]$Extra='')
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\pending-review-20261003'
$ex=@($Extra -split ','|?{$_})
& "$root\full.ps1" -Set $Set -Rounds 3 -CandAssets:$CandAssets -Extra $ex *> "$root\full-$Set.log"
'FULL_OK'
& "$root\summarize.ps1" -Sets $Set
& "$root\p99m.ps1" -Set $Set
'RUN_DONE'

# Ceiling ABBA: base = benchmark-A.exe, candidate = benchmark-X.exe, same flat-A modules; env C512_CEIL=k (A ignores it).
param([int]$K=8,[int]$Rounds=2,[int[]]$Heights=@(900,1080))
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\c512-xblock-queue-20261001'
$env:C512_CEIL="$K"
foreach($round in 1..$Rounds){& "$root\regression.ps1" -Set A -BenchName benchmark-A.exe -CandidateBenchName benchmark-X.exe -TimingOnly -TimingFrames 1000 -Heights $Heights -Batch "k$K-$round";if(!$?){throw 'ABBA failed'}}
Remove-Item Env:C512_CEIL
"TIMING_DONE k=$K"

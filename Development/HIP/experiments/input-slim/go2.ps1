$root='D:\DLSSNR-Lab\hip-backend\input-slim-20261001'
foreach($round in 4..6){& "$root\regression.ps1" -Set A -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-P.exe -CandidateAssets "$root\assets-cand" -CandidateExtra @('DLSS5_IO_FUSE=1') -TimingOnly -TimingFrames 1000 -Batch "timing-P-$round" *> "$root\go2-$round.log"}
& "$root\summarize.ps1" -Sets A;& "$root\p99m.ps1" -Set A

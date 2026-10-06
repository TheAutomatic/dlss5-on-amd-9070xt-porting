$root='D:\DLSSNR-Lab\hip-backend\composite-quant-20260930'
& "$root\regression.ps1" -Set M -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-base.exe -TimingOnly -TimingFrames 1000 -Batch "timing-base-3" *> "$root\r3.log"
& "$root\summarize.ps1" -Sets M

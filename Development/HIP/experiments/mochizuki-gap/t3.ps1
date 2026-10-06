# diagnostic: host P2 on FF modules (fb8 exports absent -> fallback) vs P1, timing 1 round
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001'
Remove-Item -Recurse -Force "$root\runtime-regression-FF-timing-P2-*" -EA 0
& "$root\regression.ps1" -Set FF -BenchName benchmark-P1.exe -Base FF -CandidateBenchName benchmark-P2.exe -TimingOnly -TimingFrames 1000 -Batch "timing-P2-1" *> "$root\t3.log"
& "$root\summarize.ps1" -Sets FF

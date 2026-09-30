$root='D:\DLSSNR-Lab\hip-backend\c256-w16-20260930'
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_VALIDATE='0';$env:SP_TRACE='0'
& "$root\regression.ps1" -Set W -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-P.exe -TimingOnly -TimingFrames 1000 -Batch "timing-P-3" *> "$root\r3.log"
& "$root\diag.ps1" *> "$root\diag.log"
& "$root\summarize.ps1" -Sets W

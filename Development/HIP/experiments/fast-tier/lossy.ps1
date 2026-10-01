# correctness-style lossy compare: base = benchmark-base + flat-A, cand = benchmark-P + flat-<Set> (+Extra flags); EXACT, 7 cases x 12 frames; PSNR
param([string]$Set,[string[]]$Extra=@())
$root='D:\DLSSNR-Lab\hip-backend\fast-tier-20261001'
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
Get-ChildItem $root -Directory -Filter "runtime-regression-$Set-q*"|Remove-Item -Recurse -Force
& "$root\regression.ps1" -Set $Set -Adaptive 0 -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-P.exe -CandidateExtra $Extra -CorrectnessOnly -Batch q0 | Select-String 'CMP'
& "$root\psnr.ps1" -Dir "$root\runtime-regression-$Set-q0" | Tee-Object "$root\psnr-$Set.txt"
Get-ChildItem "$root\runtime-regression-$Set-q0" -Recurse -Include *.f16,*.ppm|Remove-Item -Force

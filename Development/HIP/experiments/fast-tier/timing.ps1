param([string]$Set,[string[]]$Extra=@(),[int]$Rounds=3)
$root='D:\DLSSNR-Lab\hip-backend\fast-tier-20261001'
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
Get-ChildItem $root -Directory -Filter "runtime-regression-$Set-timing-*"|Remove-Item -Recurse -Force
foreach($r in 1..$Rounds){& "$root\regression.ps1" -Set $Set -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-P.exe -CandidateExtra $Extra -TimingOnly -TimingFrames 1000 -Batch "timing-$r" | Out-Null}
& "$root\summarize.ps1" -Sets $Set | Tee-Object "$root\abba-$Set.txt"; & "$root\p99m.ps1" -Set $Set | Tee-Object -Append "$root\abba-$Set.txt"
Get-ChildItem $root -Recurse -Include *.f16,*.ppm|Where-Object{$_.FullName -match 'runtime-regression'}|Remove-Item -Force

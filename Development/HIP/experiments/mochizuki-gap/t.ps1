# t.ps1 -Set X -Cand P -Roll Proll : wait until no compile/bench of others is running (<=30 min), then timing-only ABBA x3 + summary
param([string]$Set,[string]$Cand,[string]$Roll)
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001'
$t0=Get-Date
while(Get-Process|?{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^Magpie|microbench|runtime-smoke'}){if(((Get-Date)-$t0).TotalMinutes -gt 30){'BUSY TIMEOUT';exit 1};Start-Sleep 20}
& "$root\full.ps1" -Set $Set -Cand $Cand -RollHost $Roll -Rounds 3 -SkipCorrect *> "$root\timing-$Set.log"
& "$root\summarize.ps1" -Sets $Set

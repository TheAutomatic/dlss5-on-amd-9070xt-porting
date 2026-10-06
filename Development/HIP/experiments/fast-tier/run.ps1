# one item: lock, lossy PSNR + ABBA timing, unlock
param([string]$Set,[string[]]$Extra=@(),[int]$Rounds=3)
$root='D:\DLSSNR-Lab\hip-backend\fast-tier-20261001'
& "$root\lock.ps1" take "fast-tier-$Set"; if($LASTEXITCODE){exit 1}
try{ & "$root\lossy.ps1" -Set $Set -Extra $Extra; & "$root\timing.ps1" -Set $Set -Extra $Extra -Rounds $Rounds } finally { & "$root\lock.ps1" drop "fast-tier-$Set" }

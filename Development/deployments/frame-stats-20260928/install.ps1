# Frame-time log (DLSS5_FRAME_STATS) for Stellar Blade: swaps dlss5-amd.addon64 and sets DLSS5_FRAME_STATS=5 in the flags.
# -Restore <backup dir> puts both files back. Refuses to run while the game is open.
param([string]$Restore='')
$ErrorActionPreference='Stop'
if(Get-Process SB-Win64-Shipping -ErrorAction SilentlyContinue){throw 'Stellar Blade running'}
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
$w='D:\DLSSNR-Lab\frame-stats-20260928'
if($Restore){Copy-Item "$Restore\dlss5-amd.addon64" "$g\dlss5-amd.addon64" -Force;Copy-Item "$Restore\native-game-flags.txt" "$g\DLSS5-AMD\native-game-flags.txt" -Force;"restored from $Restore";exit}
$b="$w\backups\stellar-$(Get-Date -Format yyyyMMdd-HHmmss)";New-Item -ItemType Directory -Force $b|Out-Null
Copy-Item "$g\dlss5-amd.addon64","$g\DLSS5-AMD\native-game-flags.txt" $b
Copy-Item "$w\dlss5-amd.addon64" "$g\dlss5-amd.addon64" -Force
$f="$g\DLSS5-AMD\native-game-flags.txt";$t=[IO.File]::ReadAllText($f)
if($t -match '(?m)^DLSS5_FRAME_STATS='){$t=[regex]::Replace($t,'(?m)^DLSS5_FRAME_STATS=.*$','DLSS5_FRAME_STATS=5')}else{$t=$t.TrimEnd()+"`r`n# frame-time log, one line per 5 s in DLSS5-AMD\logs\frame-stats.txt`r`nDLSS5_FRAME_STATS=5`r`n"}
[IO.File]::WriteAllText($f,$t,(New-Object Text.UTF8Encoding($false)))
"addon " + (Get-FileHash "$g\dlss5-amd.addon64").Hash.Substring(0,8)
Select-String -Path $f -Pattern '^DLSS5_FRAME_STATS=' | ForEach-Object Line
"backup $b"

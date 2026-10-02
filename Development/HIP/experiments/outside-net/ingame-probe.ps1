# ingame-probe.ps1 (outside-net, 2026-10-02): Stellar Blade in-game measurement for Zero. Run with the game CLOSED.
#   -Mode stats   : DLSS5_FRAME_STATS=5 (no flush, real frame interval). In game: stand still 30 s with NR on, then F6 (bypass) 30 s.
#   -Mode probe   : DLSS5_GAME_PROBE=1 (per-pass GPU us, flushes every frame -> fps drops; only the split matters). Stand 30 s.
#   -Mode restore : put the original flags file back and copy the logs to D:\DLSSNR-Lab\outside-net-ingame\<time>\
# Flags are backed up once to native-game-flags.txt.outside-bak; each mode starts from that backup.
param([ValidateSet('stats','probe','restore')][string]$Mode)
$ErrorActionPreference='Stop'
$d='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD';$f="$d\native-game-flags.txt";$bak="$f.outside-bak"
if(Get-Process -EA 0|?{$_.ProcessName -match 'SB-Win64|StellarBlade'}){throw 'close the game first'}
if(!(Test-Path $bak)){Copy-Item $f $bak}
$keys='DLSS5_FRAME_STATS','DLSS5_GAME_PROBE'
$base=@(Get-Content $bak|?{$l=$_;-not ($keys|?{$l -match "^\s*$_\s*="})})
if($Mode -eq 'restore'){Copy-Item $bak $f -Force;Remove-Item $bak
 $o="D:\DLSSNR-Lab\outside-net-ingame\$(Get-Date -Format yyyyMMdd-HHmmss)";New-Item -ItemType Directory -Force $o|Out-Null
 Get-ChildItem "$d\logs" -EA 0|?{$_.Name -match '^(frame-stats|native-game-probe)\.txt'}|%{Copy-Item $_.FullName $o}
 "restored; logs in $o";exit}
foreach($n in 'frame-stats.txt','native-game-probe.txt'){if(Test-Path "$d\logs\$n"){Rename-Item "$d\logs\$n" "$n.$(Get-Date -Format HHmmss).old"}}
$add=if($Mode -eq 'stats'){'DLSS5_FRAME_STATS=5'}else{'DLSS5_GAME_PROBE=1'}
[IO.File]::WriteAllLines($f,$base+@($add));"flags: $add  -> start the game"

# default-c (2026-10-03): new default = all 71 blocks + DLSS5_FAST_NUMERIC=1. In both games' DLSS5-AMD\native-game-flags.txt:
# the line DLSS5_SKIP_BLOCKS=42,43,46 becomes DLSS5_SKIP_BLOCKS= and DLSS5_FAST_NUMERIC=1 is put right after it (or an existing
# FAST_NUMERIC line is set to 1). Every other line, the line endings and the file encoding stay as they are.
# Onimusha also gets the RE9 runtime whose source default is "no skip": a flags-file line "DLSS5_SKIP_BLOCKS=" removes the
# variable (_putenv), and the old runtime then fell back to its built-in 42,43,46. fast-tier exact\ flags snapshots, switch.ps1
# and README-Zero.txt re-synced. Backups first. -RestoreBackup <stamp> puts everything back.
param([switch]$DryRun,[string]$RestoreBackup='')
$ErrorActionPreference='Stop';$P=$PSScriptRoot;$R='D:\DLSSNR-Lab\fast-tier'
$games=[ordered]@{stellar='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';oni='C:\XboxGames\Onimusha- Way of the Sword\Content'}
$oni=$games.oni
function Hs($f){(Get-FileHash $f).Hash.Substring(0,8)}
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^LOP-Win|^Magpie|^benchmark|^rt_bench|^runtime-smoke|^bench_ngx'}){throw 'game / benchmark running'}
if(Test-Path 'D:\DLSSNR-Lab\gpu.lock'){throw 'gpu.lock held'}
if($RestoreBackup){$b="D:\DLSSNR-Lab\default-c-backups\$RestoreBackup"
 foreach($k in $games.Keys){Copy-Item "$b\$k-flags.txt" "$($games[$k])\DLSS5-AMD\native-game-flags.txt" -Force}
 Copy-Item "$b\LmxxfNrRuntime.dll" "$oni\" -Force;if(Test-Path "$b\_storage_\LmxxfNrRuntime.dll"){Copy-Item "$b\_storage_\LmxxfNrRuntime.dll" "$oni\_storage_\" -Force}
 foreach($f in 'stellar-flags.txt','oni-flags.txt'){Copy-Item "$b\fast-tier\exact\$f" "$R\exact\" -Force};Copy-Item "$b\fast-tier\switch.ps1","$b\fast-tier\README-Zero.txt" $R -Force
 & "$R\switch.ps1" -Tier status;'RESTORE_DONE';return}
if((Hs "$P\LmxxfNrRuntime.dll") -ne '838A8B97'){throw 'payload runtime hash'}
# new text for one flags file; throws unless it has exactly one DLSS5_SKIP_BLOCKS line equal to 42,43,46 and at most one FAST_NUMERIC line
function NewText($path){$t=[IO.File]::ReadAllText($path);$nl=if($t.Contains("`r`n")){"`r`n"}else{"`n"}
 $lines=$t -split "`r?`n",-1
 $si=@(0..($lines.Count-1)|?{$lines[$_] -match '^\s*DLSS5_SKIP_BLOCKS\s*='});$fi=@(0..($lines.Count-1)|?{$lines[$_] -match '^\s*DLSS5_FAST_NUMERIC\s*='})
 if($si.Count -ne 1 -or $lines[$si[0]].Trim() -ne 'DLSS5_SKIP_BLOCKS=42,43,46'){throw "$path : expected one DLSS5_SKIP_BLOCKS=42,43,46 line, found $($si.Count): $($si|%{$lines[$_]})"}
 if($fi.Count -gt 1){throw "$path : several DLSS5_FAST_NUMERIC lines"}
 $lines[$si[0]]='DLSS5_SKIP_BLOCKS='
 $out=New-Object Collections.Generic.List[string];$lines|%{$out.Add($_)}
 if($fi.Count){$out[$fi[0]]='DLSS5_FAST_NUMERIC=1'}else{$out.Insert($si[0]+1,'DLSS5_FAST_NUMERIC=1')}
 return ($out -join $nl)}
$new=@{};foreach($k in $games.Keys){$new[$k]=NewText "$($games[$k])\DLSS5-AMD\native-game-flags.txt"}
'payload ok, both flags files have the expected lines'
if($DryRun){foreach($k in $games.Keys){"--- $k";Compare-Object (Get-Content "$($games[$k])\DLSS5-AMD\native-game-flags.txt") ($new[$k] -split "`r?`n")|%{"$($_.SideIndicator) $($_.InputObject)"}};'DRYRUN_OK';return}
$stamp=Get-Date -Format yyyyMMdd-HHmmss;$b="D:\DLSSNR-Lab\default-c-backups\$stamp"
New-Item -ItemType Directory -Force "$b\fast-tier\exact"|Out-Null
foreach($k in $games.Keys){Copy-Item "$($games[$k])\DLSS5-AMD\native-game-flags.txt" "$b\$k-flags.txt"}
Copy-Item "$oni\LmxxfNrRuntime.dll" $b;if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){New-Item -ItemType Directory -Force "$b\_storage_"|Out-Null;Copy-Item "$oni\_storage_\LmxxfNrRuntime.dll" "$b\_storage_\"}
Copy-Item "$R\exact\stellar-flags.txt","$R\exact\oni-flags.txt" "$b\fast-tier\exact\";Copy-Item "$R\switch.ps1","$R\README-Zero.txt" "$b\fast-tier\"
"backup -> $b  (restore: install.ps1 -RestoreBackup $stamp)"
# write with the original bytes' encoding (both are plain ASCII/UTF-8 without BOM today)
$enc=New-Object Text.UTF8Encoding($false)
foreach($k in $games.Keys){$f="$($games[$k])\DLSS5-AMD\native-game-flags.txt";[IO.File]::WriteAllText($f,$new[$k],$enc);Copy-Item $f "$R\exact\$k-flags.txt" -Force}
Copy-Item "$P\LmxxfNrRuntime.dll" "$oni\LmxxfNrRuntime.dll" -Force;if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){Copy-Item "$P\LmxxfNrRuntime.dll" "$oni\_storage_\LmxxfNrRuntime.dll" -Force}
Copy-Item "$P\switch.ps1","$P\README-Zero.txt" $R -Force
foreach($k in $games.Keys){$f="$($games[$k])\DLSS5-AMD\native-game-flags.txt";"$k flags $(Hs $f): $((Get-Content $f)|?{$_ -match '^DLSS5_(SKIP_BLOCKS|FAST_NUMERIC)='})"}
"runtime $(Hs "$oni\LmxxfNrRuntime.dll") storage $(if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){Hs "$oni\_storage_\LmxxfNrRuntime.dll"}else{'none'})"
& "$R\switch.ps1" -Tier status
'INSTALL_DONE'

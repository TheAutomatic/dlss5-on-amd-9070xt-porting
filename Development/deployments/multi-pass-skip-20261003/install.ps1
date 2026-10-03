# multi-pass-skip (2026-10-03): DLSS5_MULTI_PASS_SKIP_BLOCKS (passes 2..N only) + DLSS5_MULTI_PASS hotkey / hot reload (add-on).
# New add-on (Stellar Blade) and RE9 runtime (Onimusha, + _storage_ copy); default-config.txt = the new repo template (two/one new keys,
# defaults = previous behaviour); custom-config.txt created only when absent; native-game-flags.txt is not touched (Stellar keeps MULTI_PASS=3).
# Backups first. -RestoreBackup <stamp> puts the backed-up files back and removes the config files this install created.
param([switch]$DryRun,[string]$RestoreBackup='')
$ErrorActionPreference='Stop';$P=$PSScriptRoot
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content'
$targets=@(@{name='stellar';dir="$game\DLSS5-AMD";template='hip-game-flags.txt'},@{name='oni';dir="$oni\DLSS5-AMD";template='hip-re9-flags.txt'})
function Hs($f){if(Test-Path $f){(Get-FileHash $f).Hash.Substring(0,8)}else{'none'}}
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^LOP-Win|^Magpie|^benchmark|^rt_bench|^runtime-smoke|^bench_ngx'}){throw 'game / benchmark running'}
if(Test-Path 'D:\DLSSNR-Lab\gpu.lock'){throw 'gpu.lock held'}
if($RestoreBackup){$b="D:\DLSSNR-Lab\multi-pass-skip-backups\$RestoreBackup"
 Copy-Item "$b\dlss5-amd.addon64" "$game\" -Force;Copy-Item "$b\LmxxfNrRuntime.dll" "$oni\" -Force;if(Test-Path "$b\_storage_\LmxxfNrRuntime.dll"){Copy-Item "$b\_storage_\LmxxfNrRuntime.dll" "$oni\_storage_\" -Force}
 foreach($t in $targets){foreach($n in 'native-game-flags.txt','default-config.txt','custom-config.txt'){$src="$b\$($t.name)-$n";$dst="$($t.dir)\$n"
  if(Test-Path $src){Copy-Item $src $dst -Force}elseif(Test-Path "$b\$($t.name)-$n.absent"){if(Test-Path $dst){Remove-Item $dst -Force}}}}
 'RESTORE_DONE';return}
$want=Get-Content "$P\payload.txt"|?{$_ -match '^\w'}|%{$k,$v=$_ -split ' ';@{k=$k;v=$v}}
foreach($w in $want){if((Hs "$P\$($w.k)") -ne $w.v){throw "payload hash $($w.k)"}};"payload ok: $(($want|%{"$($_.k)=$($_.v)"}) -join ' ')"
foreach($t in $targets){if(!(Test-Path "$($t.dir)\native-game-flags.txt")){throw "missing $($t.dir)\native-game-flags.txt"}}
"before: addon $(Hs "$game\dlss5-amd.addon64") runtime $(Hs "$oni\LmxxfNrRuntime.dll") "+(($targets|%{"$($_.name) native $(Hs "$($_.dir)\native-game-flags.txt") default $(Hs "$($_.dir)\default-config.txt") custom $(Hs "$($_.dir)\custom-config.txt")"}) -join ' | ')
if($DryRun){'DRYRUN_OK';return}
$stamp=Get-Date -Format yyyyMMdd-HHmmss;$b="D:\DLSSNR-Lab\multi-pass-skip-backups\$stamp";New-Item -ItemType Directory -Force $b|Out-Null
Copy-Item "$game\dlss5-amd.addon64","$oni\LmxxfNrRuntime.dll" $b;if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){New-Item -ItemType Directory -Force "$b\_storage_"|Out-Null;Copy-Item "$oni\_storage_\LmxxfNrRuntime.dll" "$b\_storage_\"}
foreach($t in $targets){foreach($n in 'native-game-flags.txt','default-config.txt','custom-config.txt'){$f="$($t.dir)\$n";if(Test-Path $f){Copy-Item $f "$b\$($t.name)-$n"}else{New-Item -ItemType File "$b\$($t.name)-$n.absent"|Out-Null}}}
"backup $b  (restore: install.ps1 -RestoreBackup $stamp)"
foreach($t in $targets){Copy-Item "$P\$($t.template)" "$($t.dir)\default-config.txt" -Force
 if(!(Test-Path "$($t.dir)\custom-config.txt")){Copy-Item "$P\custom-config.txt" "$($t.dir)\custom-config.txt"}else{"$($t.name): custom-config.txt exists, kept"}}
Copy-Item "$P\dlss5-amd.addon64" "$game\dlss5-amd.addon64" -Force
Copy-Item "$P\LmxxfNrRuntime.dll" "$oni\LmxxfNrRuntime.dll" -Force;if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){Copy-Item "$P\LmxxfNrRuntime.dll" "$oni\_storage_\LmxxfNrRuntime.dll" -Force}
"after: addon $(Hs "$game\dlss5-amd.addon64") runtime $(Hs "$oni\LmxxfNrRuntime.dll") storage $(Hs "$oni\_storage_\LmxxfNrRuntime.dll") "+(($targets|%{"$($_.name) native $(Hs "$($_.dir)\native-game-flags.txt") default $(Hs "$($_.dir)\default-config.txt") custom $(Hs "$($_.dir)\custom-config.txt")"}) -join ' | ')
'INSTALL_DONE'

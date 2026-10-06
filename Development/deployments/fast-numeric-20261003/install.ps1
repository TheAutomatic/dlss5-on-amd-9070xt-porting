# fast-numeric (2026-10-03): DLSS5_FAST_NUMERIC runtime option. Adds c32-wave1-fast.hsaco + c64-wave2-fast.hsaco (both arches; LLVM23,
# CW_FAST_NUM 3 / W2_FAST_NUM 3) to Stellar Blade + Onimusha and the new add-on / RE9 runtime that read the option. Option default 0 =
# the hosts never open the -fast files, output as before. Existing modules and flags files untouched. Backups first; fast-tier exact\
# snapshot re-synced (SUMS + -fast copies) and the old switch replaced by one that refuses -Tier fast (obsolete).
# -RestoreBackup <stamp> puts the backed-up files back (and deletes the -fast modules).
param([switch]$DryRun,[string]$RestoreBackup='')
$ErrorActionPreference='Stop';$P=$PSScriptRoot;$R='D:\DLSSNR-Lab\fast-tier';$hip='DLSS5-AMD\native-game-tiled-assets\HIP';$arches='gfx1200','gfx1201';$new='c32-wave1-fast','c64-wave2-fast'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content'
function Hs($f){(Get-FileHash $f).Hash.Substring(0,8)}
function Sums($h){$u=New-Object Text.UTF8Encoding($false);$l=@(Get-ChildItem $h -Recurse -Filter '*.hsaco'|Sort-Object FullName|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring($h.Length+1).Replace('\','/'))"});[IO.File]::WriteAllLines("$h\SHA256SUMS",$l,$u)}
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^LOP-Win|^Magpie|^benchmark|^rt_bench|^runtime-smoke|^bench_ngx'}){throw 'game / benchmark running'}
if(Test-Path 'D:\DLSSNR-Lab\gpu.lock'){throw 'gpu.lock held'}
if($RestoreBackup){$sb="D:\DLSSNR-Lab\stellar-backups\$RestoreBackup-fastnum";$ob="D:\DLSSNR-Lab\onimusha-backups\$RestoreBackup-fastnum";$fb="$R\backups\$RestoreBackup-install-fastnum"
 foreach($d in $game,$oni){foreach($a in $arches){foreach($m in $new){Remove-Item "$d\$hip\$a\$m.hsaco" -Force -EA 0}}}
 Copy-Item "$sb\dlss5-amd.addon64" "$game\" -Force;Copy-Item "$sb\SHA256SUMS" "$game\$hip\" -Force
 Copy-Item "$ob\LmxxfNrRuntime.dll" "$oni\" -Force;if(Test-Path "$ob\_storage_\LmxxfNrRuntime.dll"){Copy-Item "$ob\_storage_\LmxxfNrRuntime.dll" "$oni\_storage_\" -Force};Copy-Item "$ob\SHA256SUMS" "$oni\$hip\" -Force
 Remove-Item "$R\exact" -Recurse -Force;Copy-Item "$fb\exact" "$R\exact" -Recurse;Copy-Item "$fb\switch.ps1","$fb\README-Zero.txt" $R -Force
 & "$R\switch.ps1" -Tier status;'RESTORE_DONE';return}
$st=& "$R\switch.ps1" -Tier status|Out-String;if($st -notmatch 'stellar : EXACT' -or $st -notmatch 'oni : EXACT'){throw "not exact:`n$st"}
$want=Get-Content "$P\payload.txt"|?{$_ -match '^\w'}|%{$k,$v=$_ -split ' ';@{k=$k;v=$v}}
foreach($w in $want){if((Hs "$P\$($w.k)") -ne $w.v){throw "payload hash $($w.k)"}}
"payload ok: $(($want|%{"$($_.k)=$($_.v)"}) -join ' ')"
foreach($d in $game,$oni){$fl="$d\DLSS5-AMD\native-game-flags.txt";if((Test-Path $fl) -and ((Get-Content $fl) -match '^\s*DLSS5_FAST_NUMERIC\s*=\s*1')){throw "$fl already sets DLSS5_FAST_NUMERIC=1"}}
if($DryRun){'DRYRUN_OK';return}
$stamp=Get-Date -Format yyyyMMdd-HHmmss
$sb="D:\DLSSNR-Lab\stellar-backups\$stamp-fastnum";New-Item -ItemType Directory -Force $sb|Out-Null;Copy-Item "$game\dlss5-amd.addon64","$game\$hip\SHA256SUMS" $sb
$ob="D:\DLSSNR-Lab\onimusha-backups\$stamp-fastnum";New-Item -ItemType Directory -Force $ob|Out-Null;Copy-Item "$oni\LmxxfNrRuntime.dll","$oni\$hip\SHA256SUMS" $ob
if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){New-Item -ItemType Directory -Force "$ob\_storage_"|Out-Null;Copy-Item "$oni\_storage_\LmxxfNrRuntime.dll" "$ob\_storage_\"}
$fb="$R\backups\$stamp-install-fastnum";New-Item -ItemType Directory -Force $fb|Out-Null;Copy-Item "$R\exact" "$fb\exact" -Recurse;Copy-Item "$R\switch.ps1","$R\README-Zero.txt" $fb
"backups $sb | $ob | $fb  (restore: install.ps1 -RestoreBackup $stamp)"
foreach($d in $game,$oni){foreach($a in $arches){foreach($m in $new){Copy-Item "$P\HIP\$a\$m.hsaco" "$d\$hip\$a\" -Force}};Sums "$d\$hip"}
Copy-Item "$P\dlss5-amd.addon64" "$game\dlss5-amd.addon64" -Force
Copy-Item "$P\LmxxfNrRuntime.dll" "$oni\LmxxfNrRuntime.dll" -Force;if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){Copy-Item "$P\LmxxfNrRuntime.dll" "$oni\_storage_\LmxxfNrRuntime.dll" -Force}
foreach($a in $arches){foreach($m in $new){Copy-Item "$P\HIP\$a\$m.hsaco" "$R\exact\$a\" -Force}}
Copy-Item "$P\switch.ps1","$P\README-Zero.txt" $R -Force
Copy-Item "$game\$hip\SHA256SUMS" "$R\exact\stellar-SHA256SUMS" -Force;Copy-Item "$oni\$hip\SHA256SUMS" "$R\exact\oni-SHA256SUMS" -Force
foreach($d in $game,$oni){foreach($a in $arches){foreach($m in $new){if((Hs "$d\$hip\$a\$m.hsaco") -ne (Hs "$P\HIP\$a\$m.hsaco")){throw "copy check $d $a $m"}}}}
if((Hs "$game\$hip\SHA256SUMS") -ne (Hs "$oni\$hip\SHA256SUMS")){throw 'SUMS differ between games'}
& "$R\switch.ps1" -Tier status
"addon $(Hs "$game\dlss5-amd.addon64") runtime $(Hs "$oni\LmxxfNrRuntime.dll") storage $(if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){Hs "$oni\_storage_\LmxxfNrRuntime.dll"}else{'none'}) stellar SUMS $(Hs "$game\$hip\SHA256SUMS") oni SUMS $(Hs "$oni\$hip\SHA256SUMS")"
'INSTALL_DONE'

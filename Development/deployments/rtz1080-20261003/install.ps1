# rtz1080 (2026-10-03): add c32-wave1-rtz.hsaco (both arches; LLVM23, HIP_C32_RTZ_ISA 2) to Stellar Blade + Onimusha, new add-on / RE9 runtime
# (HIP_C32_RTZ_TALL: 1080 tier loads the rtz file, 900/720 keep c32-wave1). Other modules untouched. Backups first; fast-tier gets
# exact\ + fast\ copies of the new module (fast = fast c32-wave1) and the switch that knows it; exact snapshot re-synced.
# -RestoreBackup <stamp> puts the backed-up files back (and deletes c32-wave1-rtz.hsaco).
param([switch]$DryRun,[string]$RestoreBackup='')
$ErrorActionPreference='Stop';$P=$PSScriptRoot;$R='D:\DLSSNR-Lab\fast-tier';$hip='DLSS5-AMD\native-game-tiled-assets\HIP';$arches='gfx1200','gfx1201'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content'
function Hs($f){(Get-FileHash $f).Hash.Substring(0,8)}
function Sums($h){$u=New-Object Text.UTF8Encoding($false);$l=@(Get-ChildItem $h -Recurse -Filter '*.hsaco'|Sort-Object FullName|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring($h.Length+1).Replace('\','/'))"});[IO.File]::WriteAllLines("$h\SHA256SUMS",$l,$u)}
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^LOP-Win|^Magpie|^benchmark|^rt_bench|^runtime-smoke'}){throw 'game / benchmark running'}
if(Test-Path 'D:\DLSSNR-Lab\gpu.lock'){throw 'gpu.lock held'}
if($RestoreBackup){$sb="D:\DLSSNR-Lab\stellar-backups\$RestoreBackup-rtz1080";$ob="D:\DLSSNR-Lab\onimusha-backups\$RestoreBackup-rtz1080";$fb="$R\backups\$RestoreBackup-install-rtz1080"
 foreach($a in $arches){Remove-Item "$game\$hip\$a\c32-wave1-rtz.hsaco","$oni\$hip\$a\c32-wave1-rtz.hsaco" -Force -EA 0}
 Copy-Item "$sb\dlss5-amd.addon64" "$game\" -Force;Copy-Item "$sb\SHA256SUMS" "$game\$hip\" -Force
 Copy-Item "$ob\LmxxfNrRuntime.dll" "$oni\" -Force;if(Test-Path "$ob\_storage_\LmxxfNrRuntime.dll"){Copy-Item "$ob\_storage_\LmxxfNrRuntime.dll" "$oni\_storage_\" -Force};Copy-Item "$ob\SHA256SUMS" "$oni\$hip\" -Force
 Remove-Item "$R\exact" -Recurse -Force;Copy-Item "$fb\exact" "$R\exact" -Recurse;Copy-Item "$fb\switch.ps1" "$R\switch.ps1" -Force
 foreach($a in $arches){Remove-Item "$R\fast\$a\c32-wave1-rtz.hsaco" -Force -EA 0}
 & "$R\switch.ps1" -Tier status;'RESTORE_DONE';return}
$st=& "$R\switch.ps1" -Tier status|Out-String;if($st -notmatch 'stellar : EXACT' -or $st -notmatch 'oni : EXACT'){throw "not exact:`n$st"}
foreach($a in $arches){if((Get-FileHash "$game\$hip\$a\c32-wave1.hsaco").Hash -ne (Get-FileHash "$oni\$hip\$a\c32-wave1.hsaco").Hash){throw "c32-wave1 $a differs between games"}}
$want=Get-Content "$P\payload.txt"|?{$_ -match '^\w'}|%{$k,$v=$_ -split ' ';@{k=$k;v=$v}}
foreach($w in $want){if((Hs "$P\$($w.k)") -ne $w.v){throw "payload hash $($w.k)"}}
"payload ok: $(($want|%{"$($_.k)=$($_.v)"}) -join ' ')"
if($DryRun){'DRYRUN_OK';return}
$stamp=Get-Date -Format yyyyMMdd-HHmmss
$sb="D:\DLSSNR-Lab\stellar-backups\$stamp-rtz1080";New-Item -ItemType Directory -Force $sb|Out-Null;Copy-Item "$game\dlss5-amd.addon64","$game\$hip\SHA256SUMS" $sb
$ob="D:\DLSSNR-Lab\onimusha-backups\$stamp-rtz1080";New-Item -ItemType Directory -Force $ob|Out-Null;Copy-Item "$oni\LmxxfNrRuntime.dll","$oni\$hip\SHA256SUMS" $ob
if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){New-Item -ItemType Directory -Force "$ob\_storage_"|Out-Null;Copy-Item "$oni\_storage_\LmxxfNrRuntime.dll" "$ob\_storage_\"}
$fb="$R\backups\$stamp-install-rtz1080";New-Item -ItemType Directory -Force $fb|Out-Null;Copy-Item "$R\exact" "$fb\exact" -Recurse;Copy-Item "$R\switch.ps1" $fb
"backups $sb | $ob | $fb  (restore: install.ps1 -RestoreBackup $stamp)"
foreach($d in $game,$oni){foreach($a in $arches){Copy-Item "$P\HIP\$a\c32-wave1-rtz.hsaco" "$d\$hip\$a\" -Force};Sums "$d\$hip"}
Copy-Item "$P\dlss5-amd.addon64" "$game\dlss5-amd.addon64" -Force
Copy-Item "$P\LmxxfNrRuntime.dll" "$oni\LmxxfNrRuntime.dll" -Force;if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){Copy-Item "$P\LmxxfNrRuntime.dll" "$oni\_storage_\LmxxfNrRuntime.dll" -Force}
foreach($a in $arches){Copy-Item "$P\HIP\$a\c32-wave1-rtz.hsaco" "$R\exact\$a\" -Force;Copy-Item "$R\fast\$a\c32-wave1.hsaco" "$R\fast\$a\c32-wave1-rtz.hsaco" -Force}
Copy-Item "$P\switch.ps1" "$R\switch.ps1" -Force
Copy-Item "$game\$hip\SHA256SUMS" "$R\exact\stellar-SHA256SUMS" -Force;Copy-Item "$oni\$hip\SHA256SUMS" "$R\exact\oni-SHA256SUMS" -Force
foreach($d in $game,$oni){foreach($a in $arches){if((Hs "$d\$hip\$a\c32-wave1-rtz.hsaco") -ne (Hs "$P\HIP\$a\c32-wave1-rtz.hsaco")){throw "copy check $d $a"}}}
& "$R\switch.ps1" -Tier status
"addon $(Hs "$game\dlss5-amd.addon64") runtime $(Hs "$oni\LmxxfNrRuntime.dll") stellar SUMS $(Hs "$game\$hip\SHA256SUMS") oni SUMS $(Hs "$oni\$hip\SHA256SUMS")"
'INSTALL_DONE'

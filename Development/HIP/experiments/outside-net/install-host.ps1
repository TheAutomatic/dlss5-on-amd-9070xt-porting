# install-host.ps1 (outside-net, 2026-10-02): host side only. Stellar dlss5-amd.addon64 -> 7FC14ECE, Onimusha LmxxfNrRuntime.dll (+ _storage_) -> 3AF64892.
# Modules, shaders, flags untouched. Backups first; fast-tier exact snapshot re-synced (modules/SUMS/flags; host files are not part of it).
$ErrorActionPreference='Stop';$src='D:\DLSSNR-Lab\hip-backend\outside-net-20261002\bin';$R='D:\DLSSNR-Lab\fast-tier'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
function Hs($f){(Get-FileHash $f).Hash.Substring(0,8)}
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^LOP-Win|^Magpie|^benchmark|^rt_bench|^rt_outside|^runtime-smoke'}){throw 'game / benchmark running'}
if(Test-Path 'D:\DLSSNR-Lab\gpu.lock'){throw 'gpu.lock held'}
$st=& "$R\switch.ps1" -Tier status|Out-String;if($st -notmatch 'stellar : EXACT' -or $st -notmatch 'oni : EXACT'){throw "not exact:`n$st"}
if((Hs "$src\dlss5-amd.addon64") -ne '7FC14ECE' -or (Hs "$src\rt-N.dll") -ne '3AF64892'){throw 'source hash'}
$stamp=Get-Date -Format yyyyMMdd-HHmmss
$sb="D:\DLSSNR-Lab\stellar-backups\$stamp-outside";New-Item -ItemType Directory -Force $sb|Out-Null;Copy-Item "$game\dlss5-amd.addon64","$game\DLSS5-AMD\native-game-flags.txt" $sb
$ob="D:\DLSSNR-Lab\onimusha-backups\$stamp-outside";New-Item -ItemType Directory -Force $ob|Out-Null;Copy-Item "$oni\LmxxfNrRuntime.dll" $ob
if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){New-Item -ItemType Directory -Force "$ob\_storage_"|Out-Null;Copy-Item "$oni\_storage_\LmxxfNrRuntime.dll" "$ob\_storage_\"}
$fb="$R\backups\$stamp-install-outside";New-Item -ItemType Directory -Force $fb|Out-Null;Copy-Item "$R\exact" "$fb\exact" -Recurse
"backups $sb | $ob | $fb (old addon $(Hs "$sb\dlss5-amd.addon64") runtime $(Hs "$ob\LmxxfNrRuntime.dll"))"
Copy-Item "$src\dlss5-amd.addon64" "$game\dlss5-amd.addon64" -Force
Copy-Item "$src\rt-N.dll" "$oni\LmxxfNrRuntime.dll" -Force;if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){Copy-Item "$src\rt-N.dll" "$oni\_storage_\LmxxfNrRuntime.dll" -Force}
Copy-Item "$game\$hip\SHA256SUMS" "$R\exact\stellar-SHA256SUMS" -Force;Copy-Item "$oni\$hip\SHA256SUMS" "$R\exact\oni-SHA256SUMS" -Force
Copy-Item "$game\DLSS5-AMD\native-game-flags.txt" "$R\exact\stellar-flags.txt" -Force;Copy-Item "$oni\DLSS5-AMD\native-game-flags.txt" "$R\exact\oni-flags.txt" -Force -EA 0
& "$R\switch.ps1" -Tier status
"addon $(Hs "$game\dlss5-amd.addon64") runtime $(Hs "$oni\LmxxfNrRuntime.dll") storage $(if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){Hs "$oni\_storage_\LmxxfNrRuntime.dll"}else{'none'}) SUMS $(Hs "$game\$hip\SHA256SUMS")"
'INSTALL_DONE'

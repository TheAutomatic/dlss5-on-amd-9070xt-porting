# install.ps1 (next-candidate, 2026-10-02): installs D:\DLSSNR-Lab\next-candidate into Stellar Blade AND Onimusha. NOT run by the agent; Zero decides.
# Contents: HIP\gfx1200 + HIP\gfx1201 (62 modules = main's full recipe, build-modules.ps1 -RowOpts -PrebuiltDir; only c32-wave1 / c64-wave2 (LLVM23; c64 with HIP_BARRIER_FENCE 1)
# and c512-m32-deep (max-ilp) differ in code from 0.39), dlss5-amd.addon64 (HEAD; byte-identical to installed 053C3589), LmxxfNrRuntime.dll
# (HEAD 73D4C25C: + DLSS5_STYLE from the flags file). Shaders and flags unchanged.
# Steps: refuse if a game / benchmark runs or a tier is not EXACT; verify package SHA256SUMS; back up everything touched; copy; read back;
# rewrite HIP\SHA256SUMS; mirror to Onimusha (+ _storage_ runtime); sync the fast-tier exact snapshot; print status.  -DryRun = checks only.
param([switch]$DryRun)
$ErrorActionPreference='Stop';$pkg=$PSScriptRoot;$R='D:\DLSSNR-Lab\fast-tier'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
function Hs($f){(Get-FileHash $f).Hash}
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^LOP-Win|^Magpie|^benchmark|^rt_bench|^runtime-smoke'}){throw 'game / benchmark running: close it first'}
if(Test-Path 'D:\DLSSNR-Lab\gpu.lock'){throw "gpu.lock held: $(Get-Content D:\DLSSNR-Lab\gpu.lock)"}
$st=& "$R\switch.ps1" -Tier status|Out-String;if($st -notmatch 'stellar : EXACT' -or $st -notmatch 'oni : EXACT'){throw "games not on exact tier:`n$st"}
# package integrity
$bad=0;foreach($l in Get-Content "$pkg\SHA256SUMS"){$h,$p=$l -split '  ',2;if((Hs "$pkg\$($p.Replace('/','\'))").ToLower() -ne $h){$bad++;"BAD $p"}};if($bad){throw 'package SHA256SUMS mismatch'}
foreach($a in 'gfx1200','gfx1201'){if(@(Get-ChildItem "$pkg\HIP\$a" -Filter *.hsaco).Count -ne 31){throw "package $a not 31 modules"};Get-ChildItem "$game\$hip\$a" -Filter *.hsaco|?{!(Test-Path "$pkg\HIP\$a\$($_.Name)")}|%{throw "installed module not in package: $a\$($_.Name)"}}
"package OK; current addon $((Hs "$game\dlss5-amd.addon64").Substring(0,8)) runtime $((Hs "$oni\LmxxfNrRuntime.dll").Substring(0,8))"
if($DryRun){'DRYRUN_OK';return}
$stamp=Get-Date -Format yyyyMMdd-HHmmss
# ---- backups
$sb="D:\DLSSNR-Lab\stellar-backups\$stamp-next";New-Item -ItemType Directory -Force $sb|Out-Null
Copy-Item "$game\$hip" "$sb\HIP" -Recurse;Copy-Item "$game\dlss5-amd.addon64","$game\DLSS5-AMD\native-game-flags.txt" $sb
$ob="D:\DLSSNR-Lab\onimusha-backups\$stamp-next";New-Item -ItemType Directory -Force $ob|Out-Null
Copy-Item "$oni\$hip" "$ob\HIP" -Recurse;Copy-Item "$oni\LmxxfNrRuntime.dll" $ob;if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){New-Item -ItemType Directory -Force "$ob\_storage_"|Out-Null;Copy-Item "$oni\_storage_\LmxxfNrRuntime.dll" "$ob\_storage_\"}
$fb="$R\backups\$stamp-install-next";New-Item -ItemType Directory -Force $fb|Out-Null;Copy-Item "$R\exact" "$fb\exact" -Recurse;Copy-Item "$R\fast" "$fb\fast" -Recurse
"backups $sb | $ob | $fb"
# ---- Stellar
foreach($a in 'gfx1200','gfx1201'){foreach($f in Get-ChildItem "$pkg\HIP\$a" -Filter *.hsaco){Copy-Item $f.FullName "$game\$hip\$a\" -Force;if((Hs "$game\$hip\$a\$($f.Name)") -ne (Hs $f.FullName)){throw "readback $a $($f.Name)"}}}
$u=New-Object Text.UTF8Encoding($false);$h="$game\$hip";$l=@(Get-ChildItem $h -Recurse -Filter '*.hsaco'|Sort-Object FullName|%{"$((Hs $_.FullName).ToLower())  $($_.FullName.Substring($h.Length+1).Replace('\','/'))"});[IO.File]::WriteAllLines("$h\SHA256SUMS",$l,$u)
Copy-Item "$pkg\dlss5-amd.addon64" "$game\dlss5-amd.addon64" -Force
# ---- Onimusha: mirror modules + SUMS, runtime (+ _storage_)
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$game\$hip\$a\*.hsaco" "$oni\$hip\$a" -Force};Copy-Item "$game\$hip\SHA256SUMS" "$oni\$hip\SHA256SUMS" -Force
foreach($f in Get-ChildItem "$game\$hip" -Recurse -File){$o=$f.FullName.Replace($game,$oni);if((Hs $o) -ne (Hs $f.FullName)){throw "Onimusha mismatch $o"}}
Copy-Item "$pkg\LmxxfNrRuntime.dll" "$oni\LmxxfNrRuntime.dll" -Force;if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){Copy-Item "$pkg\LmxxfNrRuntime.dll" "$oni\_storage_\LmxxfNrRuntime.dll" -Force}
# ---- fast-tier exact snapshot (to-exact must restore this install)
foreach($a in 'gfx1200','gfx1201'){foreach($m in 'c32-wave1','c64-wave2','deep_fast-packed'){Copy-Item "$game\$hip\$a\$m.hsaco" "$R\exact\$a\" -Force}}
Copy-Item "$game\$hip\SHA256SUMS" "$R\exact\stellar-SHA256SUMS" -Force;Copy-Item "$oni\$hip\SHA256SUMS" "$R\exact\oni-SHA256SUMS" -Force
Copy-Item "$game\DLSS5-AMD\native-game-flags.txt" "$R\exact\stellar-flags.txt" -Force;Copy-Item "$oni\DLSS5-AMD\native-game-flags.txt" "$R\exact\oni-flags.txt" -Force -EA 0
& "$R\switch.ps1" -Tier status
"addon $((Hs "$game\dlss5-amd.addon64").Substring(0,8)) runtime $((Hs "$oni\LmxxfNrRuntime.dll").Substring(0,8)) SUMS $((Hs "$game\$hip\SHA256SUMS").Substring(0,8))"
'INSTALL_DONE  (rollback: copy the backups above back, or rerun with the backup folder contents)'

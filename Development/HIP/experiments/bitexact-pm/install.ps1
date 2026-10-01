# install.ps1 -Tag t -Modules 'deep_fast-packed,...' [-Addon <path>] [-Runtime <path>] [-DecodeShader <path>] [-AddFlags 'K=V,...']
# Stellar: modules from build-final\<arch> (both arches), optional add-on / decode shader / flag lines; Onimusha: modules mirrored from
# Stellar, optional RE9 runtime. Everything touched is backed up first. Then the fast-tier exact snapshot is synced (to-exact must
# keep the new cut): exact\<arch>\{c32-wave1,c64-wave2,deep_fast-packed} = installed, exact\<g>-SHA256SUMS / <g>-flags.txt = installed,
# fast\<arch>\deep_fast-packed = installed deep_fast-packed when -FastDeep (its fast recipe was only the bit-exact HIP_DEC_F8W).
param([string]$Tag,[string]$Modules='',[string]$Addon='',[string]$Runtime='',[string]$DecodeShader='',[string]$AddFlags='',[switch]$FastDeep)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\bitexact-pm-20261001';$R='D:\DLSSNR-Lab\fast-tier'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
$assets='DLSS5-AMD\native-game-tiled-assets'
if(Get-Process|?{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^LOP-Win|^benchmark|^rt_bench|^runtime-smoke'}){throw 'game/GPU busy'}
if(Test-Path 'D:\DLSSNR-Lab\fast-tier\status.ps1'){$st=& "$R\switch.ps1" -Tier status|Out-String;if($st -notmatch 'stellar : EXACT' -or $st -notmatch 'oni : EXACT'){throw "games not on exact tier:`n$st"}}
$stamp=Get-Date -Format yyyyMMdd-HHmmss
function Hs($f){(Get-FileHash $f).Hash}
function Sums($h){$u=New-Object Text.UTF8Encoding($false);$l=@(Get-ChildItem $h -Recurse -Filter '*.hsaco'|Sort-Object FullName|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring($h.Length+1).Replace('\','/'))"});[IO.File]::WriteAllLines("$h\SHA256SUMS",$l,$u);$l.Count}
$mods=@($Modules -split ','|?{$_})
# ---- backups (whole HIP trees + add-on + flags + decode shader / runtimes + fast-tier exact snapshot)
$sb="$root\backups\stellar-$stamp-$Tag";New-Item -ItemType Directory -Force $sb|Out-Null
Copy-Item "$game\$hip" "$sb\HIP" -Recurse;Copy-Item "$game\dlss5-amd.addon64","$game\DLSS5-AMD\native-game-flags.txt","$game\$assets\native_codec_decode.hlsl" $sb
$ob="D:\DLSSNR-Lab\onimusha-backups\$stamp-$Tag";New-Item -ItemType Directory -Force $ob|Out-Null
Copy-Item "$oni\$hip" "$ob\HIP" -Recurse;Copy-Item "$oni\LmxxfNrRuntime.dll" $ob;if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){New-Item -ItemType Directory -Force "$ob\_storage_"|Out-Null;Copy-Item "$oni\_storage_\LmxxfNrRuntime.dll" "$ob\_storage_\"}
$fb="$R\backups\$stamp-install-$Tag";New-Item -ItemType Directory -Force $fb|Out-Null;Copy-Item "$R\exact" "$fb\exact" -Recurse;Copy-Item "$R\fast" "$fb\fast" -Recurse
"backups $sb | $ob | $fb"
# ---- Stellar
foreach($a in 'gfx1200','gfx1201'){foreach($m in $mods){$src="$root\build-final\$a\$m.hsaco";if(!(Test-Path $src)){throw "missing $src"};Copy-Item $src "$game\$hip\$a\$m.hsaco" -Force;if((Hs "$game\$hip\$a\$m.hsaco") -ne (Hs $src)){throw 'module readback'}}}
"stellar sums $(Sums "$game\$hip")"
if($Addon){Copy-Item $Addon "$game\dlss5-amd.addon64" -Force}
if($DecodeShader){Copy-Item $DecodeShader "$game\$assets\native_codec_decode.hlsl" -Force}
if($AddFlags){$ff="$game\DLSS5-AMD\native-game-flags.txt";$fl=[IO.File]::ReadAllText($ff);if($fl.Length -and !$fl.EndsWith("`n")){$fl+="`r`n"}
 foreach($kv in $AddFlags -split ','){$k=$kv.Split('=')[0];if($fl -match "(?m)^\s*$k\s*="){throw "flag $k already present"};$fl+="$kv`r`n"};[IO.File]::WriteAllText($ff,$fl)}
# ---- Onimusha: mirror modules, optional runtime
foreach($a in 'gfx1200','gfx1201'){Get-ChildItem "$oni\$hip\$a" -Filter '*.hsaco'|?{!(Test-Path "$game\$hip\$a\$($_.Name)")}|%{throw "Onimusha-only module $($_.Name)"};Copy-Item "$game\$hip\$a\*.hsaco" "$oni\$hip\$a" -Force}
Copy-Item "$game\$hip\SHA256SUMS" "$oni\$hip\SHA256SUMS" -Force
foreach($f in Get-ChildItem "$game\$hip" -Recurse -File){$o=$f.FullName.Replace($game,$oni);if((Hs $o) -ne (Hs $f.FullName)){throw "Onimusha mismatch $o"}}
if($Runtime){Copy-Item $Runtime "$oni\LmxxfNrRuntime.dll" -Force;if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){Copy-Item $Runtime "$oni\_storage_\LmxxfNrRuntime.dll" -Force}}
# ---- fast-tier exact snapshot
foreach($a in 'gfx1200','gfx1201'){foreach($m in 'c32-wave1','c64-wave2','deep_fast-packed'){Copy-Item "$game\$hip\$a\$m.hsaco" "$R\exact\$a\" -Force}
 if($FastDeep){Copy-Item "$game\$hip\$a\deep_fast-packed.hsaco" "$R\fast\$a\" -Force}}
Copy-Item "$game\$hip\SHA256SUMS" "$R\exact\stellar-SHA256SUMS" -Force;Copy-Item "$oni\$hip\SHA256SUMS" "$R\exact\oni-SHA256SUMS" -Force
Copy-Item "$game\DLSS5-AMD\native-game-flags.txt" "$R\exact\stellar-flags.txt" -Force;Copy-Item "$oni\DLSS5-AMD\native-game-flags.txt" "$R\exact\oni-flags.txt" -Force -EA 0
& "$R\switch.ps1" -Tier status
"addon $((Hs "$game\dlss5-amd.addon64").Substring(0,8)) decode $((Hs "$game\$assets\native_codec_decode.hlsl").Substring(0,8)) runtime $((Hs "$oni\LmxxfNrRuntime.dll").Substring(0,8))"
foreach($a in 'gfx1200','gfx1201'){foreach($m in $mods){"$a $m $((Hs "$game\$hip\$a\$m.hsaco").Substring(0,8))"}}
'INSTALL_DONE'

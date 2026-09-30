# FW2 install: Stellar = add-on from HEAD (FFN _w2 launch) + c512-m32-deep (C512_FFN_ONE 2) both arches; Onimusha = RE9 runtime from HEAD + modules mirrored. Flags untouched. Backups first.
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
$oni='C:\XboxGames\Onimusha- Way of the Sword\Content'
if(Get-Process|?{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^LOP-Win'}){throw 'game running'}
$stamp=Get-Date -Format yyyyMMdd-HHmmss;$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
function Bk($base,$rels,$dst){foreach($r in $rels){$d=Join-Path $dst $r;New-Item -ItemType Directory -Force (Split-Path $d)|Out-Null;Copy-Item (Join-Path $base $r) $d}}
function Sums($h){$u=New-Object Text.UTF8Encoding($false);$l=@(Get-ChildItem $h -Recurse -Filter '*.hsaco'|Sort-Object FullName|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring($h.Length+1).Replace('\','/'))"});[IO.File]::WriteAllLines("$h\SHA256SUMS",$l,$u);$l.Count}
$flags=Get-Content "$game\DLSS5-AMD\native-game-flags.txt" -Raw
foreach($e in 'DLSS5_DIRECT_IO=3','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_HIP_SWIN_RUN=1'){if($flags -notmatch "(?m)^\s*$e\s*$"){throw "flag $e"}}
$sb="$root\backups\stellar-$stamp-ffnw2"
Bk $game (@('dlss5-amd.addon64',"$hip\SHA256SUMS")+@('gfx1200','gfx1201'|%{"$hip\$_\c512-m32-deep.hsaco"})) $sb
Copy-Item "$root\dlss5-amd.addon64" "$game\dlss5-amd.addon64" -Force
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$root\build-final\$a\c512-m32-deep.hsaco" "$game\$hip\$a\c512-m32-deep.hsaco" -Force}
"stellar modules $(Sums "$game\$hip")"
if((Get-Content "$game\DLSS5-AMD\native-game-flags.txt" -Raw) -cne $flags){throw 'flags changed'}
"STELLAR backup=$sb addon=$((Get-FileHash "$game\dlss5-amd.addon64").Hash)"
$ob="D:\DLSSNR-Lab\onimusha-backups\$stamp-ffnw2"
$orels=@('LmxxfNrRuntime.dll')+$(if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){@('_storage_\LmxxfNrRuntime.dll')}else{@()})+@(Get-ChildItem "$oni\$hip" -Recurse -File|%{$_.FullName.Substring($oni.Length+1)})
Bk $oni $orels $ob
Copy-Item "$root\LmxxfNrRuntime.dll" "$oni\LmxxfNrRuntime.dll" -Force
if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){Copy-Item "$root\LmxxfNrRuntime.dll" "$oni\_storage_\LmxxfNrRuntime.dll" -Force}
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$game\$hip\$a\*.hsaco" "$oni\$hip\$a" -Force}
"oni modules $(Sums "$oni\$hip")"
"ONI backup=$ob runtime=$((Get-FileHash "$oni\LmxxfNrRuntime.dll").Hash)"

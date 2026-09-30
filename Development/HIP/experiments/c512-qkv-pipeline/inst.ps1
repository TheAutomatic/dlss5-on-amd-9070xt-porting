# c512-qkv-pipeline install: Stellar + Onimusha c512-m32-mh (both arches) from build-final; add-on/runtime/flags untouched; backups first.
$ErrorActionPreference='Stop';$mine='D:\DLSSNR-Lab\hip-backend\c512-qkv-pipeline-20261001'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
if(Get-Process|?{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^LOP-Win'}){throw 'game running'}
$flags=Get-Content "$game\DLSS5-AMD\native-game-flags.txt" -Raw
foreach($e in 'DLSS5_DIRECT_IO=3','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_HIP_SWIN_RUN=1'){if($flags -notmatch "(?m)^\s*$e\s*$"){throw "flag $e"}}
$stamp=Get-Date -Format yyyyMMdd-HHmmss
function Sums($h){$u=New-Object Text.UTF8Encoding($false);$l=@(Get-ChildItem $h -Recurse -Filter '*.hsaco'|Sort-Object FullName|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring($h.Length+1).Replace('\','/'))"});[IO.File]::WriteAllLines("$h\SHA256SUMS",$l,$u);$l.Count}
$sb="$mine\backups\stellar-$stamp-qkvdeep";$ob="D:\DLSSNR-Lab\onimusha-backups\$stamp-qkvdeep"
foreach($a in 'gfx1200','gfx1201'){foreach($p in @(@($game,$sb),@($oni,$ob))){New-Item -ItemType Directory -Force "$($p[1])\$a"|Out-Null;Copy-Item "$($p[0])\$hip\$a\c512-m32-mh.hsaco" "$($p[1])\$a\"}}
Copy-Item "$game\$hip\SHA256SUMS" $sb;Copy-Item "$oni\$hip\SHA256SUMS" $ob -EA 0
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$mine\build-final\$a\c512-m32-mh.hsaco" "$game\$hip\$a\" -Force;Copy-Item "$mine\build-final\$a\c512-m32-mh.hsaco" "$oni\$hip\$a\" -Force}
"stellar $(Sums "$game\$hip") oni $(Sums "$oni\$hip")"
foreach($a in 'gfx1200','gfx1201'){"$a stellar $((Get-FileHash "$game\$hip\$a\c512-m32-mh.hsaco").Hash.Substring(0,8)) oni $((Get-FileHash "$oni\$hip\$a\c512-m32-mh.hsaco").Hash.Substring(0,8))"}
if((Get-Content "$game\DLSS5-AMD\native-game-flags.txt" -Raw) -cne $flags){throw 'flags changed'}
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash.Substring(0,8)) runtime $((Get-FileHash "$oni\LmxxfNrRuntime.dll").Hash.Substring(0,8)) backups $sb $ob"

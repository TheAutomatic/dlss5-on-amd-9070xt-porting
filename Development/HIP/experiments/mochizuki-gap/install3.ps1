# U4 install: c512-m32-mh (both arches) into Stellar and Onimusha; add-on, runtime, flags untouched. Backups first.
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content'
if(Get-Process|?{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^LOP-Win'}){throw 'game running'}
$stamp=Get-Date -Format yyyyMMdd-HHmmss;$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
function Sums($h){$u=New-Object Text.UTF8Encoding($false);$l=@(Get-ChildItem $h -Recurse -Filter '*.hsaco'|Sort-Object FullName|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring($h.Length+1).Replace('\','/'))"});[IO.File]::WriteAllLines("$h\SHA256SUMS",$l,$u);$l.Count}
$flags=Get-Content "$game\DLSS5-AMD\native-game-flags.txt" -Raw
foreach($base in @(@($game,"$root\backups\stellar-$stamp-u4"),@($oni,"D:\DLSSNR-Lab\onimusha-backups\$stamp-u4"))){
 $b=$base[1];foreach($a in 'gfx1200','gfx1201'){New-Item -ItemType Directory -Force "$b\$hip\$a"|Out-Null;Copy-Item "$($base[0])\$hip\$a\c512-m32-mh.hsaco" "$b\$hip\$a\"};Copy-Item "$($base[0])\$hip\SHA256SUMS" "$b\$hip\"
 foreach($a in 'gfx1200','gfx1201'){Copy-Item "$root\build-final\$a\c512-m32-mh.hsaco" "$($base[0])\$hip\$a\c512-m32-mh.hsaco" -Force}
 "$($base[0]) modules $(Sums "$($base[0])\$hip") backup=$b"}
if((Get-Content "$game\DLSS5-AMD\native-game-flags.txt" -Raw) -cne $flags){throw 'flags changed'}
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash.Substring(0,8)) oni-runtime $((Get-FileHash "$oni\LmxxfNrRuntime.dll").Hash.Substring(0,8))"

# verify.ps1: after install, both games' 62 modules == build-style (file hash), add-on / runtime / shaders == final\ / src-shaders, fast-tier status
$root='D:\DLSSNR-Lab\hip-backend\rebuild-baseline-20261001'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
function Hx($f){(Get-FileHash $f).Hash.Substring(0,8)}
foreach($g in @(@('stellar',$game),@('oni',$oni))){$bad=0;foreach($a in 'gfx1200','gfx1201'){foreach($f in Get-ChildItem "$root\build-style\$a" -Filter *.hsaco){if((Hx "$($g[1])\$hip\$a\$($f.Name)") -ne (Hx $f.FullName)){$bad++;"MISMATCH $($g[0]) $a $($f.Name)"}}};"$($g[0]) modules mismatches=$bad count=$(@(Get-ChildItem "$($g[1])\$hip" -Recurse -Filter *.hsaco).Count)"}
"addon $(Hx "$game\dlss5-amd.addon64") expect $(Hx "$root\final\dlss5-amd.addon64")"
"runtime $(Hx "$oni\LmxxfNrRuntime.dll") storage $(if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){Hx "$oni\_storage_\LmxxfNrRuntime.dll"}else{'none'}) expect $(Hx "$root\final\LmxxfNrRuntime.dll")"
foreach($s in 'native_codec_decode.hlsl','native_text_overlay.hlsl'){"$s $(Hx "$game\DLSS5-AMD\native-game-tiled-assets\$s") expect $(Hx "$root\src-shaders\$s")"}
"stellar SUMS $(Hx "$game\$hip\SHA256SUMS") oni SUMS $(Hx "$oni\$hip\SHA256SUMS") exact-stellar $(Hx 'D:\DLSSNR-Lab\fast-tier\exact\stellar-SHA256SUMS')"
& 'D:\DLSSNR-Lab\fast-tier\switch.ps1' -Tier status

# assets-base = installed Stellar native-game-tiled-assets (minus HIP); assets-cand = same + repo native_codec_decode.hlsl (NATIVE_CODEC_NEURAL_BUFFER)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\bitexact-pm-20261001'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets'
foreach($n in 'assets-base','assets-cand'){if(Test-Path "$root\$n"){Remove-Item "$root\$n" -Recurse -Force};New-Item -ItemType Directory "$root\$n"|Out-Null
 Get-ChildItem $g | Where-Object {$_.Name -ne 'HIP'} | ForEach-Object {Copy-Item $_.FullName "$root\$n" -Recurse}}
Copy-Item "$root\native_codec_decode.hlsl" "$root\assets-cand\native_codec_decode.hlsl" -Force
foreach($n in 'assets-base','assets-cand'){"$n decode $((Get-FileHash "$root\$n\native_codec_decode.hlsl").Hash.Substring(0,8)) files $(@(Get-ChildItem "$root\$n" -Recurse -File).Count)"}
"old lab assets-base vs game: $(@(Compare-Object (Get-ChildItem "$root\assets-base" -Recurse -File|Get-FileHash|%{$_.Hash}) (Get-ChildItem 'D:\DLSSNR-Lab\hip-backend\input-slim-20261001\assets-base' -Recurse -File|Get-FileHash|%{$_.Hash})).Count) diffs"
'ASSETS_DONE'

# setup.ps1: harness from bitexact-pm (idle pinned both sides), flat-A = installed Stellar gfx1201 (31), flat-H = HEAD build gfx1201,
# assets-base = installed assets (minus HIP), assets-cand = + HEAD native_codec_decode.hlsl / native_text_overlay.hlsl
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\rebuild-baseline-20261001';$s='D:\DLSSNR-Lab\hip-backend\bitexact-pm-20261001'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets'
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1','full.ps1'){(Get-Content "$s\$f" -Raw).Replace('bitexact-pm-20261001','rebuild-baseline-20261001')|Set-Content "$root\$f"}
if((Get-Content "$root\regression.ps1" -Raw) -notmatch 'ADAPTIVE_IDLE_MS=1000000000'){throw 'idle pin missing'}
foreach($n in 'A','H'){Remove-Item "$root\flat-$n" -Recurse -Force -EA 0;New-Item -ItemType Directory "$root\flat-$n"|Out-Null}
Copy-Item "$root\installed\stellar\gfx1201\*.hsaco" "$root\flat-A";Copy-Item "$root\build-head\gfx1201\*.hsaco" "$root\flat-H"
foreach($n in 'assets-base','assets-cand'){Remove-Item "$root\$n" -Recurse -Force -EA 0;New-Item -ItemType Directory "$root\$n"|Out-Null;Get-ChildItem $g|?{$_.Name -ne 'HIP'}|%{Copy-Item $_.FullName "$root\$n" -Recurse}}
Copy-Item "$root\src-shaders\native_codec_decode.hlsl","$root\src-shaders\native_text_overlay.hlsl" "$root\assets-cand" -Force
"flatA $(@(gci "$root\flat-A" -Filter *.hsaco).Count) flatH $(@(gci "$root\flat-H" -Filter *.hsaco).Count) cand-decode $((Get-FileHash "$root\assets-cand\native_codec_decode.hlsl").Hash.Substring(0,8))"
'SETUP_DONE'

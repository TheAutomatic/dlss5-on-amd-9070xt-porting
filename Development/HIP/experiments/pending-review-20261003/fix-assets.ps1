$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\pending-review-20261003'
$s='D:\DLSSNR-Lab\hip-backend\config-layers-20261003\assets-base'
Remove-Item "$root\assets-base" -Recurse -Force -EA 0
Copy-Item $s "$root\assets-base" -Recurse
Remove-Item "$root\assets-cand" -Recurse -Force -EA 0
Copy-Item "$root\assets-base" "$root\assets-cand" -Recurse
Copy-Item "$root\native_codec_decode.hlsl" "$root\assets-cand\native_codec_decode.hlsl" -Force
if(!(Test-Path "$root\assets-base\block0-ffn.f16")){throw 'base still incomplete'}
"base $((Get-ChildItem $root\assets-base | Measure-Object).Count) entries; decode-cand $((Get-FileHash "$root\assets-cand\native_codec_decode.hlsl").Hash.Substring(0,8))"
'ASSETS_FIXED'

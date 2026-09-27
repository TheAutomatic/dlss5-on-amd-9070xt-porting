param([string]$Variant='base',[int]$Rounds=8,[int]$Frames=8,[string]$Sizes='1920x1080,1280x720,1707x961',[int]$Pdl=1)
$ErrorActionPreference='Stop'
$lab='D:\DLSSNR-Lab\re9-runtime-leak-20260927'
$old='D:\DLSSNR-Lab\re9-runtime-flags-20260926'
$games=Get-Process SB-Win64-Shipping,LOP-Win64-Shipping,OnimushaWotS,re9 -ErrorAction SilentlyContinue
if($games){throw 'Game running'}
$env:DLSS5_HIP_PDL="$Pdl"
$env:DLSS5_NETWORK_HEIGHT='auto'
$env:LMXXF_SHADER_DIR="$old\new\DLSS5-AMD\native-game-tiled-assets"
$env:LMXXF_WEIGHTS_DIR=$env:LMXXF_SHADER_DIR
& "$old\in\rt_bench.exe" "$lab\$Variant\LmxxfNrRuntime.dll" "$old\new\DLSS5-AMD\native-game-tiled-assets\HIP" $Sizes $Frames $Rounds *> "$lab\$Variant-pdl$Pdl.log"
if($LASTEXITCODE){throw "bench failed: $LASTEXITCODE"}
Get-Content "$lab\$Variant-pdl$Pdl.log" | Select-String 'round=|rt_bench:'

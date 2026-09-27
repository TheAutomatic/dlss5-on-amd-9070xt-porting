param([string]$Variant='final2')
$ErrorActionPreference='Stop'
$r='D:\DLSSNR-Lab\re9-runtime-leak-20260927'
$assets='D:\DLSSNR-Lab\re9-runtime-flags-20260926\new\DLSS5-AMD\native-game-tiled-assets'
if(Get-Process SB-Win64-Shipping,LOP-Win64-Shipping,OnimushaWotS,re9,rt_bench,benchmark -ErrorAction SilentlyContinue){throw 'GPU busy'}
$env:LMXXF_SHADER_DIR=$assets;$env:LMXXF_WEIGHTS_DIR=$assets
$env:DLSS5_HIP_PDL='1';$env:DLSS5_NETWORK_HEIGHT='auto'
& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$r\$Variant\LmxxfNrRuntime.dll" "$assets\HIP" *> "$r\$Variant-smoke.log"
if($LASTEXITCODE){throw 'runtime-smoke failed'}
foreach($height in '1080','900'){
 $env:DLSS5_NETWORK_HEIGHT=$height
 & 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$r\$Variant\LmxxfNrRuntime.dll" "$assets\HIP" '1707x961' 24 1 *> "$r\$Variant-hash-$height.log"
 if($LASTEXITCODE){throw "hash $height failed"}
}
Get-Content "$r\$Variant-smoke.log" | Select-Object -Last 4
foreach($height in '1080','900'){Get-Content "$r\$Variant-hash-$height.log" | Select-String 'round=|rt_bench'}

$ErrorActionPreference='Stop'
if(Get-Process SB-Win64-Shipping,LOP-Win64-Shipping,OnimushaWotS,re9,rt_bench,benchmark -ErrorAction SilentlyContinue){throw 'GPU busy'}
$r='D:\DLSSNR-Lab\re9-runtime-leak-20260927'
$env:DLSS5_HIP_PDL='1'
& "$r\bridge_probe.exe" 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\new\DLSS5-AMD\native-game-tiled-assets' 24 > "$r\bridge.log"
if($LASTEXITCODE){throw 'bridge probe failed'}
Get-Content "$r\bridge.log" | Select-Object -First 2 -Last 4

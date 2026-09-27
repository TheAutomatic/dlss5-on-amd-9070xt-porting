$ErrorActionPreference='Stop'
if(Get-Process SB-Win64-Shipping,LOP-Win64-Shipping,OnimushaWotS,re9,rt_bench,benchmark -ErrorAction SilentlyContinue){throw 'GPU busy'}
$r='D:\DLSSNR-Lab\re9-runtime-leak-20260927'
& "$r\module_probe.exe" 50 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\new\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201' > "$r\module.log"
if($LASTEXITCODE){throw 'module probe failed'}
Get-Content "$r\module.log" | Select-Object -First 1 -Last 1

$ErrorActionPreference='Stop'
if(Get-Process SB-Win64-Shipping,LOP-Win64-Shipping,OnimushaWotS,re9,rt_bench -ErrorAction SilentlyContinue){throw 'GPU busy'}
$r='D:\DLSSNR-Lab\re9-runtime-leak-20260927'
foreach($v in 0,1){& "$r\semaphore_probe.exe" 100 $v > "$r\semaphore-$v.log";if($LASTEXITCODE){throw 'probe failed'};Get-Content "$r\semaphore-$v.log" | Select-Object -First 1 -Last 1}

$root='D:\DLSSNR-Lab\hip-backend\swin-body-gap-20261001'
& "$root\build.ps1" -Name prod -Module c64-wave2
& "$root\build.ps1" -Name lb -Module c64-wave2 -Defs 'W2_UP_LOW_BYTES 1'
New-Item -ItemType Directory -Force "$root\flat-LB"|Out-Null;Copy-Item "$root\flat-A\*.hsaco" "$root\flat-LB" -Force;Copy-Item "$root\build-lb\gfx1201\c64-wave2.hsaco" "$root\flat-LB" -Force
try{& "$root\full.ps1" -Set LB -Rounds 3 *> "$root\full-LB.log";'FULL OK'}catch{"FULL FAIL $_"}
Get-Content "$root\full-LB.log" | Select-String 'SAME|FAIL|changed|DONE|W2_UP|throw' | Select-Object -Last 30
& "$root\summarize.ps1" -Sets LB;& "$root\p99m.ps1" -Set LB

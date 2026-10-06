$r='D:\DLSSNR-Lab\hip-backend\fast-tier-20261001'
& "$r\build.ps1" -Name prod -Module c64-wave2
& "$r\build.ps1" -Name prod -Module swin-persistent
& "$r\build.ps1" -Name prod -Module c32-wave1
& "$r\build.ps1" -Name mf -Module c64-wave2 -Defs 'W2_FAST_NUM 3'
& "$r\build.ps1" -Name ms -Module swin-persistent -Defs 'W2_FAST_NUM 3'

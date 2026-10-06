$r='D:\DLSSNR-Lab\hip-backend\fast-tier-20261001'
& "$r\build.ps1" -Name prod -Module c32-wave1
& "$r\build.ps1" -Name cf7 -Module c32-wave1 -Defs 'CW_FAST_NUM 7'
& "$r\build.ps1" -Name cf3b -Module c32-wave1 -Defs 'CW_FAST_NUM 3'

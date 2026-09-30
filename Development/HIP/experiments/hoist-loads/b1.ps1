$r='D:\DLSSNR-Lab\hip-backend\hoist-loads-20260930'
& "$r\build.ps1" -Name prod-c64 -Module c64-wave2
& "$r\build.ps1" -Name h15 -Module c64-wave2 -Defs 'W2_HOIST_LOADS 15'
& "$r\build.ps1" -Name prod-sp -Module swin-persistent
& "$r\build.ps1" -Name sp15 -Module swin-persistent -Defs 'W2_HOIST_LOADS 15'

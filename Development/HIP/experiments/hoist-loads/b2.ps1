$r='D:\DLSSNR-Lab\hip-backend\hoist-loads-20260930'
& "$r\build.ps1" -Name prod-c32 -Module c32-wave1
& "$r\build.ps1" -Name u3 -Module c32-wave1 -Defs 'CW_HOIST_UP 3'
& "$r\run.ps1" -Name CU -Builds u3 -Rounds 3 -NoBuild *> "$r\go-CU.log"
'B2_DONE'

# W candidate (c64-wave2 + swin-persistent, W2_UP_ADD0 1); separate logs per step.
$root='D:\DLSSNR-Lab\hip-backend\f-sweep-20260930'
& "$root\build.ps1" -Name prod-swin-persistent -Module swin-persistent *> "$root\goW-1.log"
& "$root\build.ps1" -Name W64 -Module c64-wave2 -Defs 'W2_UP_ADD0 1' *> "$root\goW-2.log"
& "$root\build.ps1" -Name W256 -Module swin-persistent -Defs 'W2_UP_ADD0 1' *> "$root\goW-3.log"
& "$root\run.ps1" -Name W -Builds W64,W256 -Rounds 3 -NoBuild *> "$root\goW-4.log"
'GOW_DONE'

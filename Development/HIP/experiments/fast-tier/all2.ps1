$r='D:\DLSSNR-Lab\hip-backend\fast-tier-20261001'
& "$r\mkset.ps1" MF 'mf:c64-wave2'
& "$r\mkset.ps1" MS 'ms:swin-persistent'
& "$r\mkset.ps1" FAST2 'cf3:c32-wave1,ksf8:deep_fast-packed,mf:c64-wave2,ms:swin-persistent'
& "$r\run.ps1" -Set KS
& "$r\run.ps1" -Set MF
& "$r\run.ps1" -Set MS
& "$r\run.ps1" -Set FAST2 -Extra 'DLSS5_NETWORK_1080_ROWS=1088'
"ALL2 DONE $(Get-Date -Format s)"

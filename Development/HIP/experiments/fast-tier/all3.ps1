$r='D:\DLSSNR-Lab\hip-backend\fast-tier-20261001'
& "$r\mkset.ps1" FAST3 'cf3:c32-wave1,f8w:deep_fast-packed,mf:c64-wave2'
& "$r\run.ps1" -Set FAST3 -Extra 'DLSS5_NETWORK_1080_ROWS=1088'
Get-ChildItem $r -Directory -Filter 'runtime-regression*'|Remove-Item -Recurse -Force
"ALL3 DONE $(Get-Date -Format s)"

$r='D:\DLSSNR-Lab\hip-backend\fast-tier-20261001'
& "$r\mkset.ps1" PK 'cf7:c32-wave1'
& "$r\mkset.ps1" CF2 'cf3:c32-wave1'
& "$r\mkset.ps1" FAST4 'cf7:c32-wave1,f8w:deep_fast-packed,mf:c64-wave2'
& "$r\run.ps1" -Set PK
& "$r\lock.ps1" take fast-tier-CF2; try{& "$r\timing.ps1" -Set CF2}finally{& "$r\lock.ps1" drop fast-tier-CF2}
& "$r\run.ps1" -Set FAST4 -Extra 'DLSS5_NETWORK_1080_ROWS=1088'
Get-ChildItem $r -Directory -Filter 'runtime-regression*'|Remove-Item -Recurse -Force
"ALL4 DONE $(Get-Date -Format s)"

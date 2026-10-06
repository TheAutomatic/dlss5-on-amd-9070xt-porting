$r='D:\DLSSNR-Lab\hip-backend\fast-tier-20261001'
& "$r\mkset.ps1" H 'head:deep_fast-packed'
& "$r\mkset.ps1" CF 'cf3:c32-wave1'
& "$r\mkset.ps1" KS 'ks:deep_fast-packed'
& "$r\mkset.ps1" DEC 'f8w:deep_fast-packed'
& "$r\mkset.ps1" R88 ''
& "$r\mkset.ps1" FAST 'cf3:c32-wave1,ksf8:deep_fast-packed'
& "$r\lock.ps1" take fast-tier-H; try{& "$r\lossy.ps1" -Set H}finally{& "$r\lock.ps1" drop fast-tier-H}
& "$r\run.ps1" -Set CF
& "$r\run.ps1" -Set KS
& "$r\run.ps1" -Set DEC -Extra 'DLSS5_IO_FUSE=1'
& "$r\run.ps1" -Set R88 -Extra 'DLSS5_NETWORK_1080_ROWS=1088'
& "$r\run.ps1" -Set FAST -Extra 'DLSS5_IO_FUSE=1','DLSS5_NETWORK_1080_ROWS=1088'
"ALL1 DONE $(Get-Date -Format s)"

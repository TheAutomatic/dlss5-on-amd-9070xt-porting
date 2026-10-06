# step 1 install: deep_fast-packed with HIP_DEC_WIDE 1 (module only; installed add-on/RE9 runtime already pick *_w), fast-tier synced, RE9 replay
$root='D:\DLSSNR-Lab\hip-backend\bitexact-pm-20261001'
& "$root\install.ps1" -Tag decwide -Modules 'deep_fast-packed' -FastDeep
$ob=Get-ChildItem 'D:\DLSSNR-Lab\onimusha-backups' -Directory -Filter '*-decwide'|Sort-Object Name|Select-Object -Last 1
& "$root\rt9.ps1" -Backup $ob.FullName
& 'D:\DLSSNR-Lab\fast-tier\switch.ps1' -Tier status

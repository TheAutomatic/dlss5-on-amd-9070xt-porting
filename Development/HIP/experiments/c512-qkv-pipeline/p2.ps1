& 'D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001\q.ps1' -Name fp8mix -Mods c512-m32-deep=fp8mix -SkipTiming
$D='D:\DLSSNR-Lab\hip-backend\c512-qkv-pipeline-20261001\dup.ps1'
foreach($r in 1..3){foreach($v in 'ffa0','ffa4','ffa1'){& $D -Rounds 1 -Frames 400 -Mods "c512-m32-deep=$v" -Cases 'base' -Prefix "$v-y$r-"}}

$Q='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001\q.ps1'
& $Q -Name fp8mix -Mods c512-m32-deep=fp8mix -Rounds 2 -SkipCorrect
& $Q -Name fp8mx2 -Mods c512-m32-deep=fp8mx2 -Rounds 2

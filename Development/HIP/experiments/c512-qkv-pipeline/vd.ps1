$Q='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001\q.ps1'
& $Q -Name vq3 -Mods vit-stream=vq3 -Host_ Pvd -BaseHost P6 -Rounds 3
& $Q -Name dp3b -Mods deep_fast-packed=dp3 -Host_ Pvd -BaseHost P6 -Rounds 3 -SkipCorrect

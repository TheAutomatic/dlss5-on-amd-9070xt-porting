$Q='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001\q.ps1'
& $Q -Name dp1 -Mods deep_fast-packed=dp1 -SkipTiming
& $Q -Name dp2 -Mods deep_fast-packed=dp2 -SkipTiming
& $Q -Name dp3 -Mods deep_fast-packed=dp3 -Host_ Pvd -BaseHost P6 -Rounds 3

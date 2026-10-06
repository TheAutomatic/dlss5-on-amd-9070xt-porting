$r='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001'
Get-ChildItem $r -Directory -Filter 'runtime-regression-*'|?{$_.Name -match '-(d4s|b8v1|b8W|b8v3)-'}|%{Get-ChildItem $_.FullName -Recurse -File|?{$_.Extension -notin '.csv','.log','.txt','.json'}|Remove-Item -Force}
"free GB $([int]((Get-PSDrive D).Free/1GB))"

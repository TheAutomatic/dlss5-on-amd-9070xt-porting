Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^Magpie|^jobbench|^rtc_compile'}|Select-Object Id,ProcessName
Get-ChildItem D:\DLSSNR-Lab\hip-backend -Directory|Sort-Object LastWriteTime|Select-Object -Last 5 Name,LastWriteTime
Get-ChildItem D:\DLSSNR-Lab\hip-backend\vit-attention-20260929 -File|Select-Object Name

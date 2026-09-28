$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\float-fma'
$files=@('D:\DLSSNR-Lab\hip-backend\live-menu-before.f16',"$r\benchmark.exe","$r\temporal-network.exe","$r\temporal-sample.exe")
Get-FileHash $files|Select-Object Path,Hash|ConvertTo-Json|Set-Content "$r\baseline-context.json"

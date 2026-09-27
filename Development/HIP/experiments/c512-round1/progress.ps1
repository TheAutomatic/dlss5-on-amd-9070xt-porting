$r='D:\DLSSNR-Lab\hip-backend\c512-round1'
if(Test-Path "$r\suite-status.txt"){Get-Content "$r\suite-status.txt"}
Get-ChildItem $r -Filter '*.log' | Where-Object {$_.Name -match '^(correct|adaptive|timing)-'} | Sort-Object LastWriteTime -Descending | Select-Object -First 2 | ForEach-Object {Write-Output $_.Name;Get-Content $_.FullName -Tail 3}

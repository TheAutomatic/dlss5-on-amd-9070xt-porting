$r='D:\DLSSNR-Lab\hip-backend\hoist-loads-20260930'
$f=@(Get-ChildItem $r -Recurse -File -Include *.f16,*.ppm|?{$_.FullName -notmatch '\\backups\\'});$s=($f|Measure-Object Length -Sum).Sum;$f|Remove-Item -Force
"removed $($f.Count) files $([math]::Round($s/1GB,2)) GB";(Get-PSDrive D).Free/1GB

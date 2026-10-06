param([switch]$Do)
$r='D:\DLSSNR-Lab\hip-backend';$keepLab='fma|deep-tail-20260930'
$keepSub='^(capture|assets|backups|input|fixture|golden)'
$rows=@()
foreach($lab in Get-ChildItem $r -Directory){ if($lab.Name -match $keepLab){continue}
 foreach($sub in Get-ChildItem $lab.FullName -Directory){ if($sub.Name -match $keepSub){continue}
  $f=@(Get-ChildItem $sub.FullName -Recurse -File -Include *.f16,*.ppm -ErrorAction SilentlyContinue | ?{$_.FullName -notmatch '\\backups\\'})
  if($f.Count){$s=($f|Measure-Object Length -Sum).Sum;$rows+=[pscustomobject]@{lab=$lab.Name;sub=$sub.Name;n=$f.Count;GB=[math]::Round($s/1GB,2)}
   if($Do){$f|Remove-Item -Force}}}}
$rows|Export-Csv D:\DLSSNR-Lab\cleanup-20260930.csv -NoTypeInformation
$rows|group lab|%{[pscustomobject]@{GB=[math]::Round(($_.Group|Measure-Object GB -Sum).Sum,1);lab=$_.Name}}|sort GB -desc|ft -auto|Out-String -Width 200
"TOTAL GB $([math]::Round(($rows|Measure-Object GB -Sum).Sum,1))"
Get-PSDrive D|select Free

$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\deep-layers'
$rows=@();$hashes=@()
foreach($d in Get-ChildItem $r -Directory -Filter 'runtime-regression-*'){
 if($d.Name -match 'invalid|overlap-rejected'){continue}
 foreach($slot in Get-ChildItem $d.FullName -Directory){
  $csv="$($slot.FullName)\rgb.csv";if(!(Test-Path $csv)){continue};$v=@(Import-Csv $csv)
  if($v.Count -in 200,1000){$mean=($v|Where-Object{[int]$_.frame -ge $(if($v.Count -eq 1000){200}else{32})}|Measure-Object wall_ms -Average).Average;$rows+=[pscustomobject]@{batch=$d.Name;slot=$slot.Name;frames=$v.Count;mean_ms=$mean;invalid=($v|Where-Object {$_.checked -eq '1'}|Measure-Object invalid -Sum).Sum}}
  if($v.Count -eq 12){foreach($f in Get-ChildItem $slot.FullName -Filter '*frame-*.f16'){$hashes+=[pscustomobject]@{batch=$d.Name;slot=$slot.Name;frame=$f.Name;sha=(Get-FileHash $f.FullName).Hash}}}
 }
}
$rows | Export-Csv -NoTypeInformation "$r\timings.csv"
$hashes | Export-Csv -NoTypeInformation "$r\frame-hashes.csv"

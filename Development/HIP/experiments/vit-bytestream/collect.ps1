param([switch]$OnlyModules)
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\vit-bytestream'
function HashModules {
 $items=@(foreach($dir in Get-ChildItem $r -Directory -Filter 'build-*'){Get-ChildItem $dir.FullName -Recurse -Filter '*.hsaco'})
 if($items.Count -lt 2){throw 'Incomplete module builds'}
 $items|ForEach-Object { "$((Get-FileHash $_.FullName).Hash) $($_.FullName)" }|Set-Content "$r\module-hashes.txt"
}
if($OnlyModules){HashModules;exit}
$rows=@();$hashes=@()
foreach($dir in Get-ChildItem $r -Directory -Filter 'runtime-regression-*'){
 foreach($case in Get-ChildItem $dir.FullName -Directory){
  if(Test-Path "$($case.FullName)\rgb.csv"){
   $frames=@(Import-Csv "$($case.FullName)\rgb.csv");$skip=if($frames.Count -eq 12){1}else{200}
   $mean=($frames|Where-Object{[int]$_.frame -ge $skip}|Measure-Object wall_ms -Average).Average
   $rows += [pscustomobject]@{set_batch=$dir.Name;tag=$case.Name;frames=$frames.Count;mean_ms=$mean;sha256=(Get-FileHash "$($case.FullName)\rgb.f16").Hash}
  }
  foreach($f in Get-ChildItem $case.FullName -Filter '*frame-*.f16'){$hashes += [pscustomobject]@{set_batch=$dir.Name;tag=$case.Name;frame=$f.Name;sha256=(Get-FileHash $f.FullName).Hash}}
 }
}
$rows|Export-Csv "$r\measurements.csv" -NoTypeInformation
$hashes|Export-Csv "$r\frame-hashes.csv" -NoTypeInformation
HashModules
$startup=@();$lines=@(Get-Content 'D:\DLSSNR-Lab\logs\native-hip.txt' -Tail 5000)
for($i=0;$i -lt $lines.Count;$i++){
 if($lines[$i] -like '*modules=*vit-bytestream*'){
  $startup+=$lines[$i];$pidToken=($lines[$i] -split ' ')[0]
  for($j=[Math]::Max(0,$i-8);$j -lt [Math]::Min($i+9,$lines.Count);$j++){if($lines[$j].StartsWith("$pidToken ") -and $lines[$j] -notlike '*modules=*'){$startup+=$lines[$j]}}
 }
}
$startup|Set-Content "$r\startup-identities.txt"
'COLLECT_DONE'

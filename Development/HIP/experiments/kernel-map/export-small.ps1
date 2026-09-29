$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\kernel-map';$d="$r\evidence-small"
New-Item -ItemType Directory -Force $d | Out-Null
foreach($batch in Get-ChildItem $r -Directory -Filter 'runtime-regression-*'){
 if($batch.Name -match 'invalid|overlap-rejected'){continue}
 foreach($slot in Get-ChildItem $batch.FullName -Directory){
  foreach($file in 'rgb.csv','flags.txt'){
   if(Test-Path "$($slot.FullName)\$file"){Copy-Item "$($slot.FullName)\$file" "$d\$($batch.Name)-$($slot.Name)-$file" -Force}
  }
 }
}

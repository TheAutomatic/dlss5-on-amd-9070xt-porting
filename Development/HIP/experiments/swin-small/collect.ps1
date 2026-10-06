param([string]$Label='prototype')
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-small-20260929'
$out="$root\collected-$Label";New-Item -ItemType Directory -Force $out|Out-Null
$hashes=@()
foreach($batch in Get-ChildItem $root -Directory -Filter 'runtime-regression-*'){
 foreach($slot in Get-ChildItem $batch.FullName -Directory){
  $dest="$out\$($batch.Name)\$($slot.Name)";New-Item -ItemType Directory -Force $dest|Out-Null
  Get-ChildItem $slot.FullName -File|Where-Object{$_.Extension -in '.csv','.log','.txt'}|Copy-Item -Destination $dest
  foreach($f in Get-ChildItem $slot.FullName -Filter '*frame-*.f16'){
   $hashes+=[pscustomobject]@{batch=$batch.Name;slot=$slot.Name;frame=$f.Name;sha=(Get-FileHash $f.FullName).Hash}
  }
 }
}
$hashes|Export-Csv "$out\hashes.csv" -NoTypeInformation
Copy-Item "$root\snapshot.json","$root\base-flags.txt" $out
Get-ChildItem $root -File|Where-Object{$_.Name -like 'topology-*.csv' -or $_.Name -eq 'occupancy.csv'}|Copy-Item -Destination $out
foreach($d in Get-ChildItem $root -Directory -Filter 'trace-*'){
 $dest="$out\$($d.Name)";New-Item -ItemType Directory -Force $dest|Out-Null
 Copy-Item "$($d.FullName)\run.log","$($d.FullName)\flags.txt" $dest
}
Compress-Archive "$out\*" "$root\collected-$Label.zip" -Force
Get-FileHash "$root\collected-$Label.zip"

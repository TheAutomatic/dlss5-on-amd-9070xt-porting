$r='D:\DLSSNR-Lab\native-1440-optimization-20261004';$dest="$r\archive";New-Item -ItemType Directory -Force $dest|Out-Null
$manifest=@();foreach($d in Get-ChildItem $r -Directory|?{$_.Name -match '^(baseline-|c256-|quality-|dense-|abba-|family-|runtime-regression-)'}){
 foreach($f in Get-ChildItem $d.FullName -Recurse -File){if($f.Extension -in '.log','.err','.csv','.txt'){$rel=$f.FullName.Substring($r.Length+1);$p=Join-Path $dest $rel;New-Item -ItemType Directory -Force (Split-Path $p)|Out-Null;Copy-Item $f.FullName $p -Force}else{if($f.Extension -in '.f16','.ppm' -or $f.Name.EndsWith('.raw.f32')){$manifest+=@{file=$f.FullName.Substring($r.Length+1);bytes=$f.Length;sha256=(Get-FileHash $f.FullName).Hash};Remove-Item $f.FullName -Force}}}}
$manifest|ConvertTo-Json -Depth 3|Set-Content "$dest\raw-output-manifest.json"
Copy-Item "$r\*.log","$r\*.json","$r\rt-*.err","$r\runtime-smoke.err" $dest -Force
Compress-Archive -Path "$dest\*" -DestinationPath "$r\archive.zip" -Force
'ARCHIVE_DONE '+(Get-Item "$r\archive.zip").Length

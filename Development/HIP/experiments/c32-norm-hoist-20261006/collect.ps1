$ErrorActionPreference='Stop'
foreach($root in 'D:\DLSSNR-Lab\c32-norm-hoist-compat-20261006','D:\DLSSNR-Lab\c32-norm-hoist-production-smoke-20261006'){
 $meta="$root\receipt";New-Item -ItemType Directory -Force $meta|Out-Null
 $frames=@();foreach($d in Get-ChildItem "$root\out" -Directory){$dest="$meta\$($d.Name)";New-Item -ItemType Directory -Force $dest|Out-Null
  foreach($f in Get-ChildItem $d.FullName -File){if($f.Extension -in '.log','.csv','.txt'){Copy-Item $f.FullName $dest -Force};if($f.Extension -eq '.f16'){$frames+=[pscustomobject]@{name="$($d.Name)/$($f.Name)";bytes=$f.Length;sha256=(Get-FileHash $f.FullName -Algorithm SHA256).Hash}}}
 }
 $frames|ConvertTo-Json -Depth 4|Set-Content "$meta\frame-hashes.json"
 $exe=@(Get-ChildItem $root -File -Filter '*.exe'|%{[pscustomobject]@{name=$_.Name;sha256=(Get-FileHash $_.FullName -Algorithm SHA256).Hash}});$exe|ConvertTo-Json|Set-Content "$meta\exe-hashes.json"
}
'CPU_RECEIPT_DONE no_kernel=1'

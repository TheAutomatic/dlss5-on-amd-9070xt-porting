# Second same-host ABBA after the first pass and pressure suite.
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-small-20260929'
& "$root\formal.ps1" -Round 3
if(!$?){throw 'Confirmation ABBA failed'}
foreach($f in (Get-Content "$root\snapshot.json" -Raw|ConvertFrom-Json)){
 if((Get-FileHash $f.path).Hash -ne $f.sha256){throw 'Installed baseline changed'}
}
'INSTALLED_SNAPSHOT_UNCHANGED=66'
& "$root\collect.ps1" -Label final
if(!$?){throw 'Collection failed'}

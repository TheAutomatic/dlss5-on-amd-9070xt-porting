$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-small-20260929'
& "$root\formal.ps1" -Round 1 -ProductionBaseline
if(!$?){throw 'Production baseline timing failed'}
foreach($round in 2,3){
 & "$root\formal.ps1" -Round $round
 if(!$?){throw 'Formal failed'}
}
& "$root\stress.ps1"
if(!$?){throw 'Pressure failed'}
& "$root\trace.ps1"
if(!$?){throw 'Trace/occupancy failed'}
foreach($f in (Get-Content "$root\snapshot.json" -Raw|ConvertFrom-Json)){
 if((Get-FileHash $f.path).Hash -ne $f.sha256){throw 'Installed baseline changed'}
}
'INSTALLED_SNAPSHOT_UNCHANGED=66'
& "$root\collect.ps1" -Label final
if(!$?){throw 'Collection failed'}

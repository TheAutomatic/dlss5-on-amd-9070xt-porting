$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929'
& "$root\short-timing.ps1" -Prefix async
if(!$?){throw 'Async timing screen failed'}
& "$root\stress.ps1"
if(!$?){throw 'Safety stress failed'}

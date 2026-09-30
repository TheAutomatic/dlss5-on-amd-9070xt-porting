$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\hip-roofline-20260930';Set-Location $r
if(!(Test-Path "$r\bw.hsaco")){throw 'no hsaco'}
& "$r\bw.exe" "$r\bw.hsaco" > "$r\bw.log" 2>&1
foreach($h in 900,1080){
 & "$r\run.ps1" -Height $h -Tag wall -Frames 1000
 & "$r\run.ps1" -Height $h -Tag span -Frames 1000 -Span 1
 & "$r\run.ps1" -Height $h -Tag prof -Frames 300 -Span 1 -Profile 1 -Exe evprof.exe
 & "$r\run.ps1" -Height $h -Tag span2 -Frames 1000 -Span 1
 & "$r\run.ps1" -Height $h -Tag wall2 -Frames 1000 }
& "$r\rejobs.ps1" > "$r\rejobs.log"
'ALL_DONE'

$ErrorActionPreference='Stop';$root=$PSScriptRoot
foreach($d in Get-ChildItem $root -Directory -Filter 'runtime-regression-*'){Get-ChildItem $d.FullName -File -Recurse -Filter '*.f16'|Remove-Item -Force}
if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -eq 'current-main-20261003'){Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}
'CLEANUP_DONE'

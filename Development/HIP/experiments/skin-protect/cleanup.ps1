$root=$PSScriptRoot
foreach($scope in 'raw','repeat'){Get-ChildItem "$root\$scope" -File -Recurse|Where-Object{$_.Extension -in '.f32','.f16','.ppm'}|Remove-Item -Force}
foreach($d in Get-ChildItem $root -Directory -Filter 'runtime-regression-*'){Get-ChildItem $d.FullName -Recurse -File -Filter '*.f16'|Remove-Item -Force}
if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -eq 'skin-protect-20261004'){Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}
'LOCK_RELEASED RAW_CLEANED'

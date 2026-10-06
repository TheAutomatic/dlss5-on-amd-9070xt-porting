# pending-review-20261003: prep flat sets for IOF / F8W / VT
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\pending-review-20261003'
foreach($set in 'IOF','F8W','VT'){
 Remove-Item "$root\flat-$set" -Recurse -Force -EA 0
 Copy-Item "$root\flat-A" "$root\flat-$set" -Recurse
}
Copy-Item "$root\build-F8W\gfx1201\deep_fast-packed.hsaco" "$root\flat-F8W\deep_fast-packed.hsaco" -Force
Copy-Item "$root\build-VT\gfx1201\c512-m32-mh.hsaco" "$root\flat-VT\c512-m32-mh.hsaco" -Force
foreach($set in 'IOF','F8W','VT'){"flat-$set deep_fast-packed $((Get-FileHash "$root\flat-$set\deep_fast-packed.hsaco").Hash.Substring(0,8)) c512-m32-mh $((Get-FileHash "$root\flat-$set\c512-m32-mh.hsaco").Hash.Substring(0,8))"}
'PREP_DONE'

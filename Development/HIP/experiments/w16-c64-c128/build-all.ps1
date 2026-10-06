# Z = recipe (W2_FFN_W16_SMALL 0) must equal installed; W64 / W128 / W3 add only the C64 / C128 / both _w16 exports.
$ErrorActionPreference='Stop';$b='D:\DLSSNR-Lab\hip-backend\w16-c64-c128-20260930\build.ps1'
& $b -Name Z -Module c64-wave2
& $b -Name W64 -Module c64-wave2 -Defs 'W2_FFN_W16_SMALL 1'
& $b -Name W128 -Module c64-wave2 -Defs 'W2_FFN_W16_SMALL 2'
& $b -Name W3 -Module c64-wave2 -Defs 'W2_FFN_W16_SMALL 3'
'ALL_BUILT'

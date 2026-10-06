# Z* = recipe default (W2_FFN_W16 0) must equal installed; W* = W2_FFN_W16 1 (adds the _w16 exports only).
$ErrorActionPreference='Stop';$b='D:\DLSSNR-Lab\hip-backend\c256-w16-20260930\build.ps1'
& $b -Name Zc64 -Module c64-wave2
& $b -Name Zsp -Module swin-persistent
& $b -Name Wc64 -Module c64-wave2 -Defs 'W2_FFN_W16 1'
& $b -Name Wsp -Module swin-persistent -Defs 'W2_FFN_W16 1'
'ALL_BUILT'

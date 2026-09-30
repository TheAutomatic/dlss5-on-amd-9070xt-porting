# Z* = recipe default (C512_F_MASK 0) must equal installed; M* = C512_F_MASK 1.
$ErrorActionPreference='Stop';$b='D:\DLSSNR-Lab\hip-backend\composite-quant-c512-20260930\build.ps1'
& $b -Name Zc512 -Module c512-m32-deep
& $b -Name Zdeep -Module deep_fast-packed
& $b -Name Mc512 -Module c512-m32-deep -Defs 'C512_F_MASK 1'
& $b -Name Mdeep -Module deep_fast-packed -Defs 'C512_F_MASK 1'
'ALL_BUILT'

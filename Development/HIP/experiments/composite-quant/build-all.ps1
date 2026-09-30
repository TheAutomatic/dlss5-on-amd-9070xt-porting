# Z* = recipe default (W2_Q8_MASK 0) must equal installed; M* = W2_Q8_MASK 1.
$ErrorActionPreference='Stop';$b='D:\DLSSNR-Lab\hip-backend\composite-quant-20260930\build.ps1'
& $b -Name Zc64 -Module c64-wave2
& $b -Name Zsp -Module swin-persistent
& $b -Name Mc64 -Module c64-wave2 -Defs 'W2_Q8_MASK 1'
& $b -Name Msp -Module swin-persistent -Defs 'W2_Q8_MASK 1'
'ALL_BUILT'

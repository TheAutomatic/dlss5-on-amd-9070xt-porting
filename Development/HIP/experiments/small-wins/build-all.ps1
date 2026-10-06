# All candidate builds for small-wins-20260930
$ErrorActionPreference='Stop';$b='D:\DLSSNR-Lab\hip-backend\small-wins-20260930\build.ps1'
& $b -Name Zc32 -Module c32-wave1
& $b -Name Zmix -Module c512-m32-deep
& $b -Name Zvit -Module vit-stream
& $b -Name I -Module c32-wave1 -Defs 'CW_INPUT_HALF 7'
& $b -Name P -Module c32-wave1 -Defs 'CW_PREFIX_HALF_SOURCE 1'
& $b -Name Q -Module c32-wave1 -Defs 'CW_POST_FULL_TILE 1'
& $b -Name IP -Module c32-wave1 -Defs 'CW_INPUT_HALF 7','CW_PREFIX_HALF_SOURCE 1'
& $b -Name IPQ -Module c32-wave1 -Defs 'CW_INPUT_HALF 7','CW_PREFIX_HALF_SOURCE 1','CW_POST_FULL_TILE 1'
& $b -Name Omix -Module c512-m32-deep -Defs 'C512_MIX_OCC_LDS 4096'
& $b -Name Ovit -Module vit-stream -Defs 'VIT_CONTRACT_OCC_LDS 4096'
'ALL_BUILT'

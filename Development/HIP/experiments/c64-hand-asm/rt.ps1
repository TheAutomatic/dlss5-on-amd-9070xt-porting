$ErrorActionPreference='Stop'
$d='D:\DLSSNR-Lab\hip-backend\c64-hand-asm';$p='D:\DLSSNR-Lab\hip-backend\pack8\modules-P\gfx1201'
Copy-Item "$p\c64-wave2.hsaco.s" "$d\base.s" -Force
& "$d\asm_compile.exe" "$d\roundtrip.hsaco" "$d\base.s" gfx1201
"orig $((Get-Item "$p\c64-wave2.hsaco").Length)  rt $((Get-Item "$d\roundtrip.hsaco").Length)"

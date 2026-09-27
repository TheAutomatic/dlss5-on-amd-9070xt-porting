$ErrorActionPreference='Stop';$d='D:\DLSSNR-Lab\hip-backend\c64-hand-asm'
& D:\DLSSNR-Lab\hip-backend\check-idle.ps1
& D:\DLSSNR-Lab\dual-arch-src\rtc_compile.exe "$d\zsign.hsaco" "$d\zsign.hip" comgr gfx1201
& "$d\zsign.exe" "$d\zsign.hsaco"

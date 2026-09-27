$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c32-aco'
if(Get-Process SB-Win64-Shipping,LOP-Win64-Shipping,OnimushaWotS,re9,benchmark -ErrorAction SilentlyContinue){throw 'GPU busy'}
& 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' "$r\scalar_probe.hsaco" "$r\scalar_probe.hip" comgr gfx1201 > "$r\scalar-build.log"
if($LASTEXITCODE){throw 'probe build failed'}
& "$r\scalar_probe.exe" "$r\scalar_probe.hsaco" > "$r\scalar-probe.log"
Get-Content "$r\scalar-probe.log"
if($LASTEXITCODE){throw 'probe differences'}

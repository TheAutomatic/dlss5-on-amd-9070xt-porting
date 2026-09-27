$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c32-round2'
if(Get-Process SB-Win64-Shipping,LOP-Win64-Shipping,OnimushaWotS,re9,benchmark -ErrorAction SilentlyContinue){throw 'GPU busy'}
$s=[IO.File]::ReadAllText("$r\build-M\gfx1201\c32-wave1.generated.hip")+[IO.File]::ReadAllText("$r\mode-probe.inc")
[IO.File]::WriteAllText("$r\mode-probe.hip",$s,(New-Object Text.UTF8Encoding($false)))
& 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' "$r\mode-probe.hsaco" "$r\mode-probe.hip" comgr gfx1201 > "$r\mode-probe-build.log"
if($LASTEXITCODE){throw 'probe compile failed'}
& "$r\mode-probe.exe" "$r\mode-probe.hsaco" > "$r\mode-probe.log"
if($LASTEXITCODE){throw 'probe failed'}
Get-Content "$r\mode-probe.log"

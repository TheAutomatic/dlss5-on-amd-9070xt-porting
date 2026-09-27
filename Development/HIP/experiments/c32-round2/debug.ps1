$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c32-round2'
$env:RTC_EXTRA_OPTS='-gline-tables-only'
& 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' "$r\base-debug.hsaco" "$r\build-A\gfx1201\c32-wave1.generated.hip" comgr gfx1201
if($LASTEXITCODE){throw 'debug ISA failed'}

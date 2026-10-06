$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\post-history-gate-20261005';Remove-Item Env:RTC_EXTRA_OPTS -ErrorAction SilentlyContinue
$ErrorActionPreference='Continue'
foreach($arch in 'gfx1201','gfx1200'){& D:\DLSSNR-Lab\release-041\payload\rtc_compile.exe "$r\gate-$arch.hsaco" "$r\gate_helpers.hip" comgr $arch *> "$r\gate-$arch.compile.log";if($LASTEXITCODE -ne 0){Get-Content "$r\gate-$arch.compile.log";throw 'gate compile failed'}}

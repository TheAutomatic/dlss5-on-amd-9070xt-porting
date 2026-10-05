$ErrorActionPreference='Continue';$r='D:\DLSSNR-Lab\vit-contract960-20261005';Remove-Item Env:RTC_EXTRA_OPTS -ErrorAction SilentlyContinue
foreach($arch in 'gfx1201','gfx1200'){& D:\DLSSNR-Lab\release-041\payload\rtc_compile.exe "$r\$arch.hsaco" "$r\candidate.hip" comgr $arch *> "$r\$arch.compile.log";if($LASTEXITCODE -ne 0){Get-Content "$r\$arch.compile.log";throw 'compile failed'}}

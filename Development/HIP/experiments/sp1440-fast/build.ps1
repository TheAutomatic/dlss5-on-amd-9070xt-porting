$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$r='D:\DLSSNR-Lab\sp1440-fast-20261005';Remove-Item Env:RTC_EXTRA_OPTS -ErrorAction SilentlyContinue
foreach($arch in 'gfx1201','gfx1200'){
 & 'D:\DLSSNR-Lab\release-041\payload\rtc_compile.exe' "$r\$arch.hsaco" "$r\sp-fast.generated.hip" comgr $arch *> "$r\$arch.compile.log"
 if($LASTEXITCODE -ne 0){Get-Content "$r\$arch.compile.log";throw 'compile failed'}
 Get-FileHash "$r\$arch.hsaco"
}

$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\post-history-gate-20261005'
$mods="$r\sequence-HIP\gfx1201";New-Item -ItemType Directory -Force $mods,"$r\sequence-small","$r\sequence-1080" | Out-Null
Copy-Item D:\DLSSNR-Lab\release-041\HIP\gfx1201\*.hsaco $mods -Force
Copy-Item "$r\c32-wave1-fast.hsaco" "$mods\c32-wave1-fast.hsaco" -Force
Copy-Item D:\DLSSNR-Lab\pool64-byte-20261005\prod\gfx1201\multihead-fast-padded-wave-packed.hsaco $mods -Force
Copy-Item D:\DLSSNR-Lab\sp1440-fast-20261005\gfx1201.hsaco "$mods\swin-persistent-fast.hsaco" -Force
foreach($out in 'sequence-small','sequence-1080'){Copy-Item "$r\post70-history-head.f16" "$r\$out\post70-history-head.f16" -Force}
$env:RTC_EXTRA_OPTS='-ffp-contract=off'
$ErrorActionPreference='Continue'
& D:\DLSSNR-Lab\release-041\payload\rtc_compile.exe "$r\warp-gfx1201.hsaco" "$r\warp.hip" comgr gfx1201 *> "$r\warp.compile.log"
$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc -ne 0){Get-Content "$r\warp.compile.log";throw "Warp compile $rc"}
Get-FileHash "$r\warp-gfx1201.hsaco","$mods\c32-wave1-fast.hsaco" | Select-Object Path,Hash

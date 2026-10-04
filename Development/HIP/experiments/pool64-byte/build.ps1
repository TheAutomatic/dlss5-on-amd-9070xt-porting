$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$r='D:\DLSSNR-Lab\pool64-byte-20261005'
New-Item -ItemType Directory -Force $r | Out-Null
Copy-Item -Recurse -Force 'D:\DLSSNR-Lab\release-041\HIP' $r
foreach($arch in 'gfx1201','gfx1200') {
 & 'D:\DLSSNR-Lab\release-041\payload\rtc_compile.exe' "$r\$arch.hsaco" "$r\pool64.generated.hip" comgr $arch *> "$r\$arch.compile.log"
 if($LASTEXITCODE -ne 0){Get-Content "$r\$arch.compile.log";throw 'compile failed'}
 Get-FileHash "$r\$arch.hsaco"
}
Copy-Item -Force "$r\gfx1201.hsaco" "$r\HIP\gfx1201\multihead-fast-padded-wave-packed.hsaco"

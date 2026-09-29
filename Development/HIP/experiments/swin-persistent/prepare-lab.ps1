$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^rtc_compile'}){throw 'GPU lab busy'}
foreach($set in 'A','P'){New-Item -ItemType Directory -Force "$root\flat-$set"|Out-Null;Copy-Item "$root\baseline\gfx1201\*.hsaco" "$root\flat-$set" -Force}
Copy-Item "$root\candidate\gfx1201\swin-persistent.hsaco" "$root\flat-P" -Force
Get-FileHash "$root\benchmark-base.exe","$root\benchmark-sp.exe","$root\flat-P\swin-persistent.hsaco"|Format-List

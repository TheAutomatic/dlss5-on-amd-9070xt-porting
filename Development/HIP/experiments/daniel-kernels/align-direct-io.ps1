$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\daniel-kernels'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile'}){throw 'GPU busy'}
foreach($batch in 'r1','r2') {Rename-Item "$r\runtime-regression-P-$batch" "runtime-regression-P-$batch-overlap-rejected"}
Copy-Item 'D:\DLSSNR-Lab\zero-copy-io-20260928\benchmark-zc.exe' "$r\benchmark-zc.exe" -Force

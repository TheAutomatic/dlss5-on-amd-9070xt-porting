$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\kernel-map'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^recorder|^microbench|^rtc_compile'}){throw 'GPU busy'}
New-Item -ItemType Directory -Force "$r\synthetic"|Out-Null
$env:MAP_DIR="$r\synthetic"
$flags=@([IO.File]::ReadAllLines('D:\DLSSNR-Lab\hip-backend\deep-layers\runtime-regression-P-exact\1080-static-True\flags.txt'))+@('DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_RGB=0')
[IO.File]::WriteAllLines("$r\record-flags.txt",$flags)
& "$r\recorder-v2.exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' "$r\record-flags.txt" 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16' "$r\record" 1 0 "$r\flat-A" 0 0 0 0 > "$r\record.log"
if($LASTEXITCODE){throw 'Recorder failed'}

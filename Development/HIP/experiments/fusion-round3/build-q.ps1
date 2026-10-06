param([string]$Arch='gfx1201')
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\fusion-round3'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile'}){throw 'GPU busy'}
$d="$r\build-Q-$Arch";New-Item -ItemType Directory -Force $d|Out-Null
& 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' "$d\vit-stream.hsaco" "$r\vit-stream-Q.hip" comgr $Arch
if($LASTEXITCODE){throw 'compile'}
if($Arch -eq 'gfx1201'){foreach($set in 'Q','R'){New-Item -ItemType Directory -Force "$r\flat-$set"|Out-Null;Copy-Item "$r\flat-A\*.hsaco" "$r\flat-$set" -Force;Copy-Item "$d\vit-stream.hsaco" "$r\flat-$set" -Force}}

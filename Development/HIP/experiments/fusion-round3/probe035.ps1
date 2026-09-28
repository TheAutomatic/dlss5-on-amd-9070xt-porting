$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\fusion-round3'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile'}){throw 'GPU busy'}
$d="$r\probe035";New-Item -ItemType Directory -Force $d|Out-Null
$flags=@(Get-Content "$r\runtime-regression-P-screen\1080-motion-False\flags.txt")+@('DLSS5_NETWORK_HEIGHT=900','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_VIT_ADAPTIVE_LOG=')
[IO.File]::WriteAllLines("$d\flags.txt",$flags)
& "$r\benchmark-035.exe" 'D:\給網友打包\OptiScaler-DLSS5-AMD-0.35\DLSS5-AMD\native-game-tiled-assets' "$d\flags.txt" 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16' "$d\rgb" 2 0 "$r\flat-035" 0 1 0 0 > "$d\run.log"
if($LASTEXITCODE){throw '0.35 probe failed'}
Import-Csv "$d\rgb.csv" | Select-Object frame,invalid,wall_ms

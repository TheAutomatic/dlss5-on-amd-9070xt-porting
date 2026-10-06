$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929'
foreach($height in 900,1080){foreach($enabled in 0,1){
 if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench'}){throw 'GPU lab busy'}
 $d="$root\trace-$height-$enabled";New-Item -ItemType Directory -Force $d|Out-Null
 $flags=@(Get-Content "$root\runtime-regression-Q-correct\$height-static-True\flags.txt")+@("DLSS5_HIP_SWIN_RUN=$enabled",'DLSS5_RESIDUAL_RGB=0','DLSS5_VIT_ADAPTIVE=0')
 [IO.File]::WriteAllLines("$d\flags.txt",$flags)
 & "$root\benchmark-trace.exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' "$d\flags.txt" 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16' "$d\rgb" 1 0 "$root\flat-Q" 0 1 0 0 *> "$d\run.log"
 if($LASTEXITCODE){throw 'Trace failed'}
 $rows=@(Get-Content "$d\run.log"|Where-Object{$_ -like 'TOPO,*'})
 $rows|Set-Content "$root\topology-$height-$enabled.csv"
 "TRACE height=$height enabled=$enabled dispatches=$($rows.Count)"
}}

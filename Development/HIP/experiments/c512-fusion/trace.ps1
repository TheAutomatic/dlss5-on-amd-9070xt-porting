$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c512-fusion'
foreach($height in 900,1080){
 if(Get-Process|Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile'}){throw 'GPU busy'}
 $d="$r\trace-$height";New-Item -ItemType Directory -Force $d|Out-Null
 $flags=@([IO.File]::ReadAllLines("$r\runtime-regression-C-exact\$height-static-True\flags.txt")|Where-Object{$_ -notmatch '^DLSS5_VIT_ADAPTIVE_LOG=|^DLSS5_RESIDUAL_RGB='})+@('DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_RGB=0')
 [IO.File]::WriteAllLines("$d\flags.txt",$flags)
 & "$r\benchmark-trace.exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' "$d\flags.txt" 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16' "$d\rgb" 1 0 "$r\flat-C" 0 0 0 0 > "$d\run.log"
 if($LASTEXITCODE){throw 'trace failed'}
 (Get-Content "$d\run.log"|Where-Object{$_ -like 'TOPO,*'})|Set-Content "$r\topology-$height.csv"
}

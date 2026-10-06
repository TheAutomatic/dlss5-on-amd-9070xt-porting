$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-small-20260929'
$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_FORCE_TIMEOUT='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
foreach($pair in @(@(0,3),@(2,1),@(2,2),@(1,1),@(1,2))){foreach($height in 900,1080){
 if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^Magpie'}){throw 'GPU lab busy'}
 $tag="c$($pair[0])-s$($pair[1])";$env:SP_SMALL_CHANNELS="$($pair[0])";$env:SP_SMALL_SIDES="$($pair[1])"
 $d="$root\trace-$tag-$height";New-Item -ItemType Directory -Force $d|Out-Null
 $flags=@(Get-Content "$root\runtime-regression-P-c2-s1-a0\$height-static-True\flags.txt")+@('DLSS5_RESIDUAL_RGB=0','DLSS5_VIT_ADAPTIVE=0')
 [IO.File]::WriteAllLines("$d\flags.txt",$flags)
 & "$root\benchmark-trace.exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' "$d\flags.txt" 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16' "$d\rgb" 1 0 "$root\flat-A" 0 1 0 0 *> "$d\run.log"
 if($LASTEXITCODE){throw 'Trace failed'}
 $rows=@(Get-Content "$d\run.log"|Where-Object{$_ -like 'TOPO,*'})
 $rows|Set-Content "$root\topology-$tag-$height.csv"
 "TRACE tag=$tag height=$height dispatches=$($rows.Count)"
}}
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^Magpie'}){throw 'GPU lab busy'}
& "$root\occupancy.exe" "$root\flat-A" > "$root\occupancy.csv"
if($LASTEXITCODE){throw 'Occupancy query failed'}

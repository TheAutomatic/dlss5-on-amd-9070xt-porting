$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\competitor-timing-20260930\dj';$d="$r\logs";New-Item -ItemType Directory -Force $d|Out-Null
Copy-Item D:\DLSSNR-Lab\hip-backend\kernel-map-900-20260930\jobbench-v2.exe,D:\DLSSNR-Lab\hip-backend\kernel-map-900-20260930\daniel-gfx1201.hsaco $r -Force
$i=0;foreach($id in [IO.File]::ReadAllLines("$r\list.txt")){
 if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^recorder|^jobbench|^Magpie|^nr_graph'}){throw 'GPU busy'}
 $p=Start-Process "$r\jobbench-v2.exe" -ArgumentList @("$r\jobs\$id.bin",$r,"128","7") -NoNewWindow -PassThru -RedirectStandardOutput "$d\$id.log" -RedirectStandardError "$d\$id.err"
 if(!$p.WaitForExit(60000)){$p.Kill();"TIMEOUT $id";continue};$p.WaitForExit()
 $i++
}
"done $i"

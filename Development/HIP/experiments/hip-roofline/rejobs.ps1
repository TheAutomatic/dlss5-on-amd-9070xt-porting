# Re-time the jobs of the two modules changed after kernel-map-v3 (c512-m32-mh, deep_fast-packed) with current installed modules.
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\hip-roofline-20260930';$k='D:\DLSSNR-Lab\hip-backend\kernel-map-v3-20260930';$d="$r\logs-re";New-Item -ItemType Directory -Force $d|Out-Null
if(!(Test-Path "$r\jobs")){Copy-Item "$k\jobs","$k\synthetic-900","$k\synthetic-1080" $r -Recurse;Copy-Item "$k\jobbench-v2.exe" $r}
if(!(Test-Path "$r\flat-P")){Copy-Item "$r\flat-C" "$r\flat-P" -Recurse}
foreach($id in [IO.File]::ReadAllLines("$r\relist.txt")){ if(!$id){continue}
 if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^Magpie|^evprof'}){throw 'GPU busy'}
 $p=Start-Process "$r\jobbench-v2.exe" -ArgumentList @("$r\jobs\$id.bin",$r,'128','7') -NoNewWindow -PassThru -RedirectStandardOutput "$d\$id.log" -RedirectStandardError "$d\$id.err"
 if(!$p.WaitForExit(60000)){$p.Kill();throw "Timeout $id"};$p.WaitForExit()
 $res=Get-Content "$d\$id.log"|Where-Object{$_ -like 'RESULT,*'};if(!$res){throw "Failed $id"};"$id $res"}
'REJOBS_DONE'

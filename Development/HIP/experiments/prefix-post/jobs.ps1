# Per-kernel jobbench (8 warmup, 128 launches captured, 7 rounds median) for the pp jobs; root has flat-A/flat-X and junctions to the kernel-map synthetic weights.
param([int]$Launches=128,[int]$Rounds=7)
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\prefix-post-20260930';$k='D:\DLSSNR-Lab\hip-backend\kernel-map-900-20260930'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^jobbench|^rtc_compile|^Magpie'}){throw 'GPU busy'}
foreach($s in 'synthetic-900','synthetic-1080'){if(!(Test-Path "$r\$s")){cmd /c mklink /J "$r\$s" "$k\$s"|Out-Null}}
Copy-Item "$k\jobbench-v2.exe" $r -Force;New-Item -ItemType Directory -Force "$r\logs-jobs"|Out-Null
foreach($f in Get-ChildItem "$r\jobs" -Filter '*.bin'|Sort-Object Name){$id=$f.BaseName
 $p=Start-Process "$r\jobbench-v2.exe" -ArgumentList @($f.FullName,$r,"$Launches","$Rounds") -NoNewWindow -PassThru -RedirectStandardOutput "$r\logs-jobs\$id.log" -RedirectStandardError "$r\logs-jobs\$id.err"
 if(!$p.WaitForExit(120000)){$p.Kill();throw "Timeout $id"};$p.WaitForExit()
 $res=Get-Content "$r\logs-jobs\$id.log"|Where-Object{$_ -like 'RESULT,*'};if(!$res){Get-Content "$r\logs-jobs\$id.err";throw "Failed $id"};"$id $res"}
'JOBS_DONE'

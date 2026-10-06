param([string]$List='list-900.txt',[string]$Batch='o900',[int]$Launches=128,[int]$Rounds=7)
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\kernel-map-v3-20260930';$d="$r\logs-$Batch";New-Item -ItemType Directory -Force $d|Out-Null
if(!(Test-Path "$r\flat-P")){Copy-Item "$r\flat-A" "$r\flat-P" -Recurse}
function Idle {if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^recorder|^jobbench|^microbench|^rtc_compile|^Magpie'}){throw 'GPU busy'}}
$i=0;foreach($id in [IO.File]::ReadAllLines("$r\$List")){
 if((Test-Path "$d\$id.log") -and (Select-String -Path "$d\$id.log" -Pattern "^RESULT," -Quiet)){$i++;continue}
 Idle
 $p=Start-Process "$r\jobbench-v2.exe" -ArgumentList @("$r\jobs\$id.bin",$r,"$Launches","$Rounds") -NoNewWindow -PassThru -RedirectStandardOutput "$d\$id.log" -RedirectStandardError "$d\$id.err"
 if(!$p.WaitForExit(60000)){$p.Kill();throw "Timeout $id"};$p.WaitForExit()
 $result=Get-Content "$d\$id.log"|Where-Object{$_ -like 'RESULT,*'}
 if(!$result){Get-Content "$d\$id.err";throw "Failed $id"}
 $i++}
"DONE $Batch $i"

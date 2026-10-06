param([string]$List='ours-list.txt',[string]$Batch='ours',[int]$Launches=128,[int]$Rounds=7,[string]$Exe='jobbench-v2.exe')
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\kernel-map-900-20260930';$d="$r\logs-$Batch";New-Item -ItemType Directory -Force $d|Out-Null
function Idle {if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^recorder|^jobbench|^microbench|^rtc_compile'}){throw 'GPU busy'}}
$i=0;foreach($id in [IO.File]::ReadAllLines("$r\$List")){
 Idle
 $p=Start-Process "$r\$Exe" -ArgumentList @("$r\jobs900\$id.bin",$r,"$Launches","$Rounds") -NoNewWindow -PassThru -RedirectStandardOutput "$d\$id.log" -RedirectStandardError "$d\$id.err"
 if(!$p.WaitForExit(60000)){$p.Kill();throw "Timeout $id"};$p.WaitForExit()
 $exitCode=$p.ExitCode
 # Start-Process on Windows PowerShell occasionally leaves ExitCode null; require RESULT as well.
 $result=Get-Content "$d\$id.log"|Where-Object{$_ -like 'RESULT,*'}
 if(!$result){Get-Content "$d\$id.err";throw "Failed $id"}
 $i++;Write-Output "$i $result"
}

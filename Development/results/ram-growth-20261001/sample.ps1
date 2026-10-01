# 每 10 秒采样一次游戏进程与系统内存，跑 -Minutes 分钟，输出 CSV。
# 用法：powershell -ExecutionPolicy Bypass -File sample.ps1 -Name SB-Win64-Shipping -Minutes 10 -Out D:\DLSSNR-Lab\ram-growth-20261001\run-A.csv
param([string]$Name='SB-Win64-Shipping',[int]$Minutes=10,[int]$Interval=10,[Parameter(Mandatory=$true)][string]$Out)
$ErrorActionPreference='Stop'
$p=Get-Process $Name | Select-Object -First 1
"time,private_MiB,workingset_MiB,pagefile_MiB,handles,threads,sys_commit_MiB,sys_avail_MiB,standby_MiB,gpu_dedicated_MiB,gpu_shared_MiB" | Set-Content $Out
$end=(Get-Date).AddMinutes($Minutes)
while((Get-Date) -lt $end){
  $p.Refresh()
  $c=Get-Counter -ErrorAction SilentlyContinue -Counter @('\Memory\Committed Bytes','\Memory\Available MBytes',
    '\Memory\Standby Cache Normal Priority Bytes','\Memory\Standby Cache Reserve Bytes','\Memory\Standby Cache Core Bytes',
    "\GPU Process Memory(pid_$($p.Id)*)\Dedicated Usage","\GPU Process Memory(pid_$($p.Id)*)\Shared Usage")
  $v=@{};foreach($s in $c.CounterSamples){$v[$s.Path]=$s.CookedValue}
  $sum={param($pat)($v.Keys|Where-Object{$_ -like $pat}|ForEach-Object{$v[$_]}|Measure-Object -Sum).Sum}
  $line='{0},{1:F0},{2:F0},{3:F0},{4},{5},{6:F0},{7:F0},{8:F0},{9:F0},{10:F0}' -f (Get-Date -Format HH:mm:ss),
    ($p.PrivateMemorySize64/1MB),($p.WorkingSet64/1MB),($p.PagedMemorySize64/1MB),$p.HandleCount,$p.Threads.Count,
    ((& $sum '*committed bytes')/1MB),(& $sum '*available mbytes'),((& $sum '*standby cache*')/1MB),
    ((& $sum '*dedicated usage')/1MB),((& $sum '*shared usage')/1MB)
  Add-Content $Out $line;Write-Host $line
  Start-Sleep -Seconds $Interval
}

# locked.ps1 -Cmd '<powershell>' : take D:\DLSSNR-Lab\gpu.lock (wait <=30 min), keep it fresh every 5 min, run, drop.
param([string]$Cmd,[string]$Log)
$L='D:\DLSSNR-Lab\gpu.lock';$me='mochizuki-gap'
$t0=Get-Date
while(Test-Path $L){
 if(((Get-Date)-(Get-Item $L).LastWriteTime).TotalMinutes -gt 40){Remove-Item $L -Force;"stale lock removed";break}
 if(((Get-Date)-$t0).TotalMinutes -gt 30){"LOCK TIMEOUT: $(Get-Content $L)";exit 1}
 Start-Sleep 60}
"$me $(Get-Date -Format s)"|Out-File -Encoding ascii $L
$j=Start-Job -ScriptBlock {param($L,$me) while($true){Start-Sleep 300; if(Test-Path $L){"$me $(Get-Date -Format s) (refresh)"|Out-File -Encoding ascii $L}}} -ArgumentList $L,$me
try{ Invoke-Expression $Cmd *>&1 | Tee-Object -FilePath $Log } finally { Stop-Job $j; Remove-Job $j -Force; if((Test-Path $L) -and ((Get-Content $L) -match $me)){Remove-Item $L -Force}; "LOCK DROPPED" }

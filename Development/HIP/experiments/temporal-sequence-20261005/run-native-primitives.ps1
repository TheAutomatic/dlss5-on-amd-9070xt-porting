$ErrorActionPreference='Stop'
$r='C:\DLSSNR-Oracle\temporal-20261005'
$games='Shipping|SB-Win64|Onimusha|re9|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function AssertIdle {if(Get-Process | Where-Object {$_.ProcessName -match $games}){throw 'Game running'}}
AssertIdle
if((Get-PSDrive C).Free -lt 100GB){throw 'Output/cache C below100GB'}
$lock='D:\DLSSNR-Oracle\gpu.lock'
$owner=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try {
 $bytes=[Text.Encoding]::UTF8.GetBytes('temporal-native-primitives-20261005');$owner.Write($bytes,0,$bytes.Length)
 nvidia-smi --query-gpu=name,uuid,driver_version --format=csv,noheader | Set-Content "$r\native-device.csv"
 foreach($kind in 'sigmoid','head'){
  AssertIdle
  $psi=New-Object Diagnostics.ProcessStartInfo
  $psi.FileName="$r\nv-primitives-probe.exe";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false
  $psi.EnvironmentVariables['TEMP']="$r\cache";$psi.EnvironmentVariables['TMP']="$r\cache";$psi.EnvironmentVariables['CUDA_CACHE_PATH']="$r\cache"
  $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  $psi.Arguments="$r\gate-primitives-sm120.cubin $r\native-$kind.f32"
  if($kind -eq 'head'){$psi.Arguments="$r\gate-primitives-sm120.cubin $r\native-head.f16 $r\tap-features-all.f16 $r\post70-history-head.f16"}
  $p=New-Object Diagnostics.Process;$p.StartInfo=$psi;if(!$p.Start()){throw 'No process'}
  $out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
  while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process | Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'Game started; own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'Timeout'}}
  $p.WaitForExit();$out.Result|Set-Content "$r\native-$kind.log";$err.Result|Set-Content "$r\native-$kind.stderr"
  if($p.ExitCode -ne 0){throw "Native $kind failed $($p.ExitCode)"}
  Get-Content "$r\native-$kind.log"
 }
 Get-FileHash "$r\native-sigmoid.f32","$r\native-head.f16" | Select-Object Path,Hash
} finally {$owner.Dispose();Remove-Item $lock -Force}

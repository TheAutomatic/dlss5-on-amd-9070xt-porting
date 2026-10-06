param([ValidateSet('pair','query','delay')][string]$Mode='pair',[double]$DelayUs=0)
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\submission-pacing-20261006';$base='D:\DLSSNR-Lab\history-trial-041a-20261006';$data='D:\DLSSNR-Lab\sync-network-gap1080-20261006'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle {& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game busy/failure'};if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'game running'};if(Get-Process|Where-Object {$_.ProcessName -match '^rtc_compile$'}){throw 'compiler active'}}
$kind=if($Mode -eq 'pair'){3}elseif($Mode -eq 'query'){4}else{5};if($kind -eq 5 -and ($DelayUs -le 0 -or $DelayUs -gt 1000)){throw 'explicit bounded CPU delay required'}
Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'};New-Item -ItemType Directory -Force "$r\cache","$r\$Mode"|Out-Null
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{
 $slot=0;foreach($case in 0,$kind,$kind,0){
  Idle;$dir="$r\$Mode\slot-$slot";New-Item -ItemType Directory -Force $dir|Out-Null
  $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName="$r\benchmark-pacing.exe";$psi.Arguments="$base\assets $base\modules\gfx1201 $data\fast1-1088.flags $data\fixture\processing1088.rgba32f $dir 80 160 1920 1088 $case $DelayUs";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_') -or $key.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($key)}}
  $psi.EnvironmentVariables['TEMP']="$r\cache";$psi.EnvironmentVariables['TMP']="$r\cache";$psi.EnvironmentVariables['HIP_CACHE_DIR']="$r\cache"
  $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'probe start'};$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
  while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game started, own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'probe timeout'}}
  $p.WaitForExit();$out.Result|Set-Content "$dir\stdout.log";$err.Result|Set-Content "$dir\stderr.log";if($p.ExitCode){Get-Content "$dir\stderr.log" -Tail 5;throw "probe exit $($p.ExitCode), no repeat"};Get-Content "$dir\stdout.log"|Select-String 'SYNC_PROFILE|SYNC_NETWORK';$slot++
 }
}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force;'LOCK_RELEASED'}

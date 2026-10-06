$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\sparse-stage-20261006';$base='D:\DLSSNR-Lab\history-trial-041a-20261006';$data='D:\DLSSNR-Lab\sync-network-gap1080-20261006'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle {& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game busy/failure'};if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'game running'}}
Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
New-Item -ItemType Directory -Force "$r\cache"|Out-Null
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{
 $slot=0;foreach($kind in 0,1,0,2,0){
  Idle;$dir="$r\slot-$slot-kind-$kind";New-Item -ItemType Directory -Force $dir|Out-Null
  $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName="$r\benchmark-sparse.exe";$psi.Arguments="$base\assets $base\modules\gfx1201 $data\fast1-1088.flags $data\fixture\processing1088.rgba32f $dir 80 160 1920 1088 $kind";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_') -or $key.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($key)}}
  $psi.EnvironmentVariables['TEMP']="$r\cache";$psi.EnvironmentVariables['TMP']="$r\cache";$psi.EnvironmentVariables['HIP_CACHE_DIR']="$r\cache"
  $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'probe start'};$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
  while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game started, own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'probe timeout'}}
  $p.WaitForExit();$out.Result|Set-Content "$dir\stdout.log";$err.Result|Set-Content "$dir\stderr.log";if($p.ExitCode){Get-Content "$dir\stderr.log" -Tail 5;throw "probe exit $($p.ExitCode), no repeat"};Get-Content "$dir\stdout.log"|Select-String 'SYNC_PROFILE|SYNC_NETWORK';$slot++
 }
}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force;'LOCK_RELEASED'}

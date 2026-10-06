param([ValidateSet('900','1080')][string]$Height='900')
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\framework-single-event-20261006';$base='D:\DLSSNR-Lab\history-trial-041a-20261006'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle {& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game busy/failure'};if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'game running'};if(Get-Process|Where-Object {$_.ProcessName -match '^rtc_compile$'}){throw 'compiler active'}}
Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
New-Item -ItemType Directory -Force "$r\cache","$r\app-boundary-ABBA-$Height"|Out-Null
$baseflags=Get-Content 'D:\DLSSNR-Lab\sync-network-gap1080-20261006\fast1-1152.flags'
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{
 for($slot=0;$slot -lt 4;$slot++){
  Idle;$candidate=if($slot -eq 1 -or $slot -eq 2){1}else{0};$dir="$r\app-boundary-ABBA-$Height\slot-$slot";if(Test-Path $dir){throw 'Existing measured slot; do not overwrite/replay'};New-Item -ItemType Directory $dir|Out-Null
  [IO.File]::WriteAllLines("$dir\flags.txt",$baseflags+@("DLSS5_NETWORK_HEIGHT=$Height",'DLSS5_NETWORK_1080_ROWS=1152','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_NET_TIMING=0','DLSS5_GAME_PROBE=0','DLSS5_FRAME_STATS=0','DLSS5_HIP_SPAN_PROBE=0','DLSS5_BLACK_PROBE=0','DLSS5_HIP_DUP_PREFIX=','DLSS5_HIP_DUP_COUNT=1','DLSS5_MULTI_PASS=1','DLSS5_MULTI_PASS_PREDICT=0','DLSS5_MULTI_PASS_SKIN_PROTECT=0','DLSS5_VIT_ADAPTIVE=0','DLSS5_TEMPORAL_HISTORY_EXPERIMENT=0','DLSS5_SKIP_BLOCKS=',"DLSS5_LAB_SUBMIT_SINGLE=$candidate"))
  $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName="$r\benchmark-single-app.exe";$psi.Arguments="$base\assets $dir\flags.txt D:\DLSSNR-Lab\hip-backend\live-menu-before.f16 $dir\frame 160 0 $base\modules\gfx1201 0 1 0 0";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_') -or $key.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($key)}}
  $psi.EnvironmentVariables['TEMP']="$r\cache";$psi.EnvironmentVariables['TMP']="$r\cache";$psi.EnvironmentVariables['HIP_CACHE_DIR']="$r\cache"
  $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'probe start'};$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
  while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game started, own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'probe timeout'}}
  $p.WaitForExit();$out.Result|Set-Content "$dir\stdout.log";$err.Result|Set-Content "$dir\stderr.log";if($p.ExitCode){Get-Content "$dir\stderr.log" -Tail 6;throw "probe exit $($p.ExitCode), no repeat"};Get-Content "$dir\stdout.log" -Tail 3
 }
 foreach($name in 'frame-first.f16','frame.f16'){if((Get-FileHash "$r\app-boundary-ABBA-$Height\slot-0\$name").Hash -ne (Get-FileHash "$r\app-boundary-ABBA-$Height\slot-1\$name").Hash -or (Get-FileHash "$r\app-boundary-ABBA-$Height\slot-0\$name").Hash -ne (Get-FileHash "$r\app-boundary-ABBA-$Height\slot-2\$name").Hash -or (Get-FileHash "$r\app-boundary-ABBA-$Height\slot-0\$name").Hash -ne (Get-FileHash "$r\app-boundary-ABBA-$Height\slot-3\$name").Hash){throw 'full frame pixel mismatch'}}
 Get-FileHash 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16',"$r\benchmark-single-app.exe","$r\app-boundary-ABBA-$Height\slot-0\frame.f16"|Select-Object Path,Hash|ConvertTo-Json|Set-Content "$r\app-boundary-ABBA-$Height\fixture-hashes.json"
}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force;'LOCK_RELEASED'}

param([ValidateSet('900','1080')][string]$Height='900',[int]$Frames=160,[int]$Round=0)
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\c32-norm-hoist-framework-20261006';$base='D:\DLSSNR-Lab\history-trial-041a-20261006'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle {& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game busy/failure'};if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'game running'};if(Get-Process|Where-Object {$_.ProcessName -match '^rtc_compile$'}){throw 'compiler active'}}
Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
New-Item -ItemType Directory -Force "$r\cache","$r\ABBA-$Height-round$Round"|Out-Null
$baseflags=Get-Content 'D:\DLSSNR-Lab\sync-network-gap1080-20261006\fast1-1152.flags'
foreach($pair in @(@("$r\expected-assets.json","$base\assets"),@("$r\expected-modules.json","$base\modules\gfx1201"))){foreach($item in (Get-Content $pair[0] -Raw|ConvertFrom-Json)){$path=Join-Path $pair[1] $item.name;if((Get-Item $path).Length -ne $item.bytes -or (Get-FileHash $path -Algorithm SHA256).Hash -ne $item.sha256){throw "stock identity changed $path"}}}
foreach($side in 'A','H'){New-Item -ItemType Directory -Force "$r\modules-$side"|Out-Null;Copy-Item "$base\modules\gfx1201\*.hsaco" "$r\modules-$side" -Force}
Copy-Item 'D:\DLSSNR-Lab\c32-norm-hoist-20261006\H-canonical.hsaco' "$r\modules-H\c32-wave1-fast.hsaco" -Force
(Get-FileHash 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16' -Algorithm SHA256)|ConvertTo-Json|Set-Content "$r\HDR-input-sha.json"
if(Test-Path "$base\assets\temporal-history.txt"){throw 'unexpected legacy temporal marker'}
if((Get-Item 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16').Length -ne 7464960){throw 'HDR fixture footprint'}
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{
 for($slot=0;$slot -lt 4;$slot++){
  Idle;$side=if($slot -eq 1 -or $slot -eq 2){'H'}else{'A'};$dir="$r\ABBA-$Height-round$Round\slot-$slot";if(Test-Path $dir){throw 'Existing measured slot; do not overwrite/replay'};New-Item -ItemType Directory $dir|Out-Null
  [IO.File]::WriteAllLines("$dir\flags.txt",$baseflags+@("DLSS5_NETWORK_HEIGHT=$Height",'DLSS5_NETWORK_1080_ROWS=1152','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_NET_TIMING=0','DLSS5_HIP_INPUT_POLL=0','DLSS5_HIP_SPAN_PROBE=0','DLSS5_GAME_PROBE=0','DLSS5_BLACK_PROBE=0','DLSS5_MULTI_PASS=1','DLSS5_MULTI_PASS_PREDICT=0','DLSS5_MULTI_PASS_SKIN_PROTECT=0','DLSS5_VIT_ADAPTIVE=0','DLSS5_TEMPORAL_HISTORY_EXPERIMENT=0','DLSS5_SKIP_BLOCKS=','DLSS5_LAB_SUBMIT_SINGLE=0','DLSS5_LAB_SUBMIT_PAIR=0','DLSS5_LAB_SUBMIT_UNTIMED_PAIR=0'))
  $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName="$r\benchmark.exe";$psi.Arguments="$base\assets $dir\flags.txt D:\DLSSNR-Lab\hip-backend\live-menu-before.f16 $dir\frame $Frames 0 $r\modules-$side 0 1 0 0";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_') -or $key.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($key)}}
  $psi.EnvironmentVariables['TEMP']="$r\cache";$psi.EnvironmentVariables['TMP']="$r\cache";$psi.EnvironmentVariables['HIP_CACHE_DIR']="$r\cache"
  $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'probe start'};$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
  while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game started, own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'probe timeout'}}
  $p.WaitForExit();$out.Result|Set-Content "$dir\stdout.log";$err.Result|Set-Content "$dir\stderr.log";if($p.ExitCode){Get-Content "$dir\stderr.log" -Tail 6;throw "probe exit $($p.ExitCode), no repeat"};Get-Content "$dir\stdout.log" -Tail 3
 }
 foreach($name in 'frame-first.f16','frame.f16'){if((Get-FileHash "$r\ABBA-$Height-round$Round\slot-0\$name").Hash -ne (Get-FileHash "$r\ABBA-$Height-round$Round\slot-1\$name").Hash -or (Get-FileHash "$r\ABBA-$Height-round$Round\slot-0\$name").Hash -ne (Get-FileHash "$r\ABBA-$Height-round$Round\slot-2\$name").Hash -or (Get-FileHash "$r\ABBA-$Height-round$Round\slot-0\$name").Hash -ne (Get-FileHash "$r\ABBA-$Height-round$Round\slot-3\$name").Hash){throw 'full frame pixel mismatch'}}
 Get-FileHash 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16',"$r\benchmark.exe","$r\ABBA-$Height-round$Round\slot-0\frame.f16"|Select-Object Path,Hash|ConvertTo-Json|Set-Content "$r\ABBA-$Height-round$Round\fixture-hashes.json"
}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force;'LOCK_RELEASED'}

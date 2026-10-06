param([ValidateSet('900','1080')][string]$Height='900',[ValidateSet('untimed','timed')][string]$Mode='timed',[int]$Round=1)
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\framework-untimed-20261006';$base='D:\DLSSNR-Lab\history-trial-041a-20261006'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle {& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game busy/failure'};if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'game running'};if(Get-Process|Where-Object {$_.ProcessName -match '^rtc_compile$'}){throw 'compiler active'}}
Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
New-Item -ItemType Directory -Force "$r\cache","$r\formal-$Mode-$Height-round$Round"|Out-Null
$baseflags=Get-Content 'D:\DLSSNR-Lab\sync-network-gap1080-20261006\fast1-1152.flags'
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{
 for($slot=0;$slot -lt 4;$slot++){
  Idle;$candidate=if($slot -eq 1 -or $slot -eq 2){1}else{0};$dir="$r\formal-$Mode-$Height-round$Round\slot-$slot";if(Test-Path $dir){throw 'Existing measured slot; do not overwrite/replay'};New-Item -ItemType Directory $dir|Out-Null
  [IO.File]::WriteAllLines("$dir\flags.txt",$baseflags+@("DLSS5_NETWORK_HEIGHT=$Height",'DLSS5_NETWORK_1080_ROWS=1152','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_NET_TIMING=1','DLSS5_MULTI_PASS=1','DLSS5_MULTI_PASS_PREDICT=0','DLSS5_MULTI_PASS_SKIN_PROTECT=0','DLSS5_VIT_ADAPTIVE=0','DLSS5_TEMPORAL_HISTORY_EXPERIMENT=0','DLSS5_SKIP_BLOCKS=',"DLSS5_LAB_SUBMIT_PAIR=$(if($Mode -eq 'timed'){$candidate}else{0})","DLSS5_LAB_SUBMIT_UNTIMED_PAIR=$(if($Mode -eq 'untimed'){$candidate}else{0})"))
  $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName="$r\benchmark-framework-untimed.exe";$psi.Arguments="$base\assets $dir\flags.txt D:\DLSSNR-Lab\hip-backend\live-menu-before.f16 $dir\frame 320 0 $base\modules\gfx1201 0 1 0 0";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_') -or $key.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($key)}}
  $psi.EnvironmentVariables['TEMP']="$r\cache";$psi.EnvironmentVariables['TMP']="$r\cache";$psi.EnvironmentVariables['HIP_CACHE_DIR']="$r\cache"
  $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'probe start'};$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
  while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game started, own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'probe timeout'}}
  $p.WaitForExit();$out.Result|Set-Content "$dir\stdout.log";$err.Result|Set-Content "$dir\stderr.log";if($p.ExitCode){Get-Content "$dir\stderr.log" -Tail 6;throw "probe exit $($p.ExitCode), no repeat"};Get-Content "$dir\stdout.log" -Tail 3
 }
 foreach($name in 'frame-first.f16','frame.f16'){if((Get-FileHash "$r\formal-$Mode-$Height-round$Round\slot-0\$name").Hash -ne (Get-FileHash "$r\formal-$Mode-$Height-round$Round\slot-1\$name").Hash -or (Get-FileHash "$r\formal-$Mode-$Height-round$Round\slot-0\$name").Hash -ne (Get-FileHash "$r\formal-$Mode-$Height-round$Round\slot-2\$name").Hash -or (Get-FileHash "$r\formal-$Mode-$Height-round$Round\slot-0\$name").Hash -ne (Get-FileHash "$r\formal-$Mode-$Height-round$Round\slot-3\$name").Hash){throw 'full frame pixel mismatch'}}
 Get-FileHash 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16',"$r\benchmark-framework-untimed.exe","$r\formal-$Mode-$Height-round$Round\slot-0\frame.f16"|Select-Object Path,Hash|ConvertTo-Json|Set-Content "$r\formal-$Mode-$Height-round$Round\fixture-hashes.json"

 $a=@(Import-Csv "$r\formal-$Mode-$Height-round$Round\slot-0\frame.csv"|Select-Object -Skip 80|ForEach-Object {[double]$_.wall_ms})+@(Import-Csv "$r\formal-$Mode-$Height-round$Round\slot-3\frame.csv"|Select-Object -Skip 80|ForEach-Object {[double]$_.wall_ms})
 $b=@(Import-Csv "$r\formal-$Mode-$Height-round$Round\slot-1\frame.csv"|Select-Object -Skip 80|ForEach-Object {[double]$_.wall_ms})+@(Import-Csv "$r\formal-$Mode-$Height-round$Round\slot-2\frame.csv"|Select-Object -Skip 80|ForEach-Object {[double]$_.wall_ms})
 function P99($values){$sorted=@($values|Sort-Object);$idx=.99*($sorted.Count-1);$lo=[int][Math]::Floor($idx);$hi=[int][Math]::Ceiling($idx);return $sorted[$lo]+($idx-$lo)*($sorted[$hi]-$sorted[$lo])}
 $delta=(($b|Measure-Object -Average).Average)-(($a|Measure-Object -Average).Average);$tail=(P99 $b)-(P99 $a)
 "FORMAL_DELTA round=$Round height=$Height avg_ms=$delta p99_ms=$tail"
 if($delta -ge 0 -or $tail -gt 0){throw 'Formal slow average or tail; stop without replay'}
}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force;'LOCK_RELEASED'}

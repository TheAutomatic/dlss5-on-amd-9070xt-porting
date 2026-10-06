$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\pool-coldage-20261006';$lock='D:\DLSSNR-Lab\gpu.lock'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle{& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game-check busy'};if(Get-Process | Where-Object {$_.ProcessName -match $games}){throw 'game busy'}}
Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try {
 $tag=[Text.Encoding]::UTF8.GetBytes('pool-coldage-20261006');$f.Write($tag,0,$tag.Length)
 $env:BENCH_W='2560';$env:BENCH_H='1440';$env:BENCH_RAW_OUTPUT='1'
 $flags=@(Get-Content "$r\template-flags.txt")+@('DLSS5_MULTI_PASS=1','DLSS5_MULTI_PASS_PREDICT=0','DLSS5_MULTI_PASS_SKIN_PROTECT=0','DLSS5_FAST_NUMERIC=1','DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_REUSE_HOTKEY=0','DLSS5_MULTI_PASS_HOTKEY=0','DLSS5_NETWORK_HEIGHT=auto','DLSS5_NETWORK_FREE_RES=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_FRAME_STATS=0','DLSS5_NET_TIMING=0','DLSS5_HOT_RELOAD=0')
 $assets='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';$mods="$r\HIP\gfx1201";$input='D:\DLSSNR-Lab\hip-backend\free-res-20261002\in\in-2560x1440.f16'
 foreach($round in 1..3){$measure=@();$sha=@();$slot=0
  foreach($side in 'baseline','candidate','candidate','baseline'){
   Idle;$d="$r\round-$round-slot-$slot";New-Item -ItemType Directory -Force $d|Out-Null;[IO.File]::WriteAllLines("$d\flags.txt",$flags)
   $psi=New-Object Diagnostics.ProcessStartInfo;$psi.FileName="$r\$side.exe";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
   $psi.Arguments="$assets $d\flags.txt $input $d\out 160 0 $mods 0 1 1 0"
   $p=New-Object Diagnostics.Process;$p.StartInfo=$psi;if(!$p.Start()){throw 'Start failed'}
   $o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
   while(!$p.HasExited){Start-Sleep -Milliseconds 250;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object{$_.ProcessName -match $games}){$p.Kill();throw 'Game started; own probe only stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 90){$p.Kill();throw 'Bounded slot timeout'}}
   $p.WaitForExit();$o.Result|Set-Content "$d\run.log";$e.Result|Set-Content "$d\stderr.log";if($p.ExitCode){Get-Content "$d\stderr.log" -Tail 10;throw "runner exit $($p.ExitCode)"}
   $values=@(Import-Csv "$d\out.csv"|Where-Object{[int]$_.frame -ge 80}|ForEach-Object{[double]$_.wall_ms});$avg=($values|Measure-Object -Average).Average;$measure+=,$values;$sha+=(Get-FileHash "$d\out.raw.f32").Hash
   "SLOT round=$round slot=$slot side=$side avg=$avg";$slot++
  }
  if(@($sha|Select-Object -Unique).Count -ne 1){throw 'Raw output mismatch'}
  $a=@($measure[0]) + @($measure[3]);$b=@($measure[1])+@($measure[2]);$am=($a|Measure-Object -Average).Average;$bm=($b|Measure-Object -Average).Average
  "ROUND $round A=$am B=$bm delta=$($bm-$am) raw=SAME"
  if($bm -ge $am){'STOP_NO_STABLE_GAIN';break}
 }
} finally {$f.Dispose();Remove-Item $lock -Force}

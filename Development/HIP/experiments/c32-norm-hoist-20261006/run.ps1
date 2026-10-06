$Candidate='H';$Shape='1088'
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\c32-norm-hoist-20261006';$stair='D:\DLSSNR-Lab\vit-math-stair-20261006';$base='D:\DLSSNR-Lab\history-trial-041a-20261006';$data='D:\DLSSNR-Lab\sync-network-gap1080-20261006'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle {& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game busy/failure'};if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'game running'}}
function Probe($exe,$arguments,$dir){
 Idle;New-Item -ItemType Directory -Force $dir|Out-Null;$psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=$exe;$psi.Arguments=$arguments;$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_') -or $key.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($key)}}
 $psi.EnvironmentVariables['TEMP']="$r\cache";$psi.EnvironmentVariables['TMP']="$r\cache";$psi.EnvironmentVariables['HIP_CACHE_DIR']="$r\cache"
 $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'probe start'};$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
 while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game started, own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'probe timeout'}}
 $p.WaitForExit();$out.Result|Set-Content "$dir\stdout.log";$err.Result|Set-Content "$dir\stderr.log";if($p.ExitCode){Get-Content "$dir\stderr.log" -Tail 5;throw "probe exit $($p.ExitCode)"};Get-Content "$dir\stdout.log"|Select-String 'SYNC_PROFILE|SYNC_NETWORK|C32_NORM_GOLD|ACTUAL_OCCUPANCY|ACTUAL_PREFIX'
}
Idle;if(Get-Process rtc_compile -ErrorAction SilentlyContinue){throw 'rtc busy'};if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
foreach($pair in @(@("$r\expected-assets.json","$base\assets"),@("$r\expected-modules.json","$base\modules\gfx1201"))){foreach($item in (Get-Content $pair[0] -Raw|ConvertFrom-Json)){$path=Join-Path $pair[1] $item.name;if((Get-Item $path).Length -ne $item.bytes -or (Get-FileHash $path -Algorithm SHA256).Hash -ne $item.sha256){throw "stock identity changed $path"}}}
if((Get-FileHash "$r\A-canonical.hsaco" -Algorithm SHA256).Hash -ne (Get-FileHash "$base\modules\gfx1201\c32-wave1-fast.hsaco" -Algorithm SHA256).Hash){throw 'A not currentstock'}
if((Get-FileHash "$data\fixture\processing1088.rgba32f" -Algorithm SHA256).Hash -ne '3EF42D34CEBD1BC847E5CAA3A95B3C3B70F45C9EEED4E828A3E2F85615B49B68'){throw 'commoninput changed'}
New-Item -ItemType Directory -Force "$r\cache","$r\modules-A","$r\modules-$Candidate","$r\$Candidate-out"|Out-Null
Copy-Item "$base\modules\gfx1201\*.hsaco" "$r\modules-A" -Force;Copy-Item "$base\modules\gfx1201\*.hsaco" "$r\modules-$Candidate" -Force
Copy-Item "$r\A-canonical.hsaco" "$r\modules-A\c32-wave1-fast.hsaco" -Force;Copy-Item "$r\H-canonical.hsaco" "$r\modules-$Candidate\c32-wave1-fast.hsaco" -Force
if($Shape -eq '1088'){$w=1920;$ph=1088;$input="$data\fixture\processing1088.rgba32f";$flags=Get-Content "$data\fast1-1088.flags"}
else{$w=1600;$ph=960;$input='D:\DLSSNR-Lab\sync-network-gap-20261006\fixture\processing.rgba32f';$flags=Get-Content 'D:\DLSSNR-Lab\sync-network-gap-20261006\fast1.flags'}
[IO.File]::WriteAllLines("$r\$Candidate-out\flags-$Shape.txt",$flags+@('DLSS5_FAST_NUMERIC=1','DLSS5_MULTI_PASS=1','DLSS5_VIT_ADAPTIVE=0','DLSS5_TEMPORAL_HISTORY_EXPERIMENT=0'))
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{
 Probe "$r\occupancy-probe.exe" "$r\A-canonical.hsaco $r\H-canonical.hsaco" "$r\H-out\occupancy"
 Probe "$r\gold-probe.exe" "$r\gold-canonical.hsaco $r\H-out\unit-gold" "$r\H-out\unit-gold"
 foreach($side in 'A','H'){
  New-Item -ItemType Directory -Force "$r\trace-$side"|Out-Null
  Copy-Item "$r\modules-$side\*.hsaco" "$r\trace-$side" -Force
  Copy-Item "$r\$side-trace-canonical.hsaco" "$r\trace-$side\c32-wave1-fast.hsaco" -Force
  Probe "$r\prefix-capture.exe" "$base\assets $r\trace-$side $r\H-out\flags-1088.txt $input $r\H-out\prefix-$side 1 1 $ph" "$r\H-out\prefix-$side"
 }
 foreach($file in 'prefix-norm.u32','first.rgb32f'){
  $ha=(Get-FileHash "$r\H-out\prefix-A\$file" -Algorithm SHA256).Hash
  $ht=(Get-FileHash "$r\H-out\prefix-H\$file" -Algorithm SHA256).Hash
  "ACTUAL_PREFIX_GOLD $file equal=$($ha -eq $ht)"
  if($ha -ne $ht){throw "actual prefix/fullNN mismatch $file"}
 }

 for($slot=0;$slot -lt 4;$slot++){$side=if($slot -eq 1 -or $slot -eq 2){$Candidate}else{'A'};$dir="$r\$Candidate-out\$Shape-$slot";Probe "$stair\benchmark.exe" "$base\assets $r\modules-$side $r\$Candidate-out\flags-$Shape.txt $input $dir 80 160 $w $ph" $dir}
}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force;'LOCK_RELEASED'}

param([ValidateSet('B','C')][string]$Candidate='B',[ValidateSet('1088','900')][string]$Shape='1088')
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\vit-math-stair-20261006';$base='D:\DLSSNR-Lab\history-trial-041a-20261006';$data='D:\DLSSNR-Lab\sync-network-gap1080-20261006'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle {& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game busy/failure'};if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'game running'}}
function Probe($exe,$arguments,$dir){
 Idle;New-Item -ItemType Directory -Force $dir|Out-Null;$psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=$exe;$psi.Arguments=$arguments;$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_') -or $key.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($key)}}
 $psi.EnvironmentVariables['TEMP']="$r\cache";$psi.EnvironmentVariables['TMP']="$r\cache";$psi.EnvironmentVariables['HIP_CACHE_DIR']="$r\cache"
 $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'probe start'};$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
 while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game started, own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'probe timeout'}}
 $p.WaitForExit();$out.Result|Set-Content "$dir\stdout.log";$err.Result|Set-Content "$dir\stderr.log";if($p.ExitCode){Get-Content "$dir\stderr.log" -Tail 5;throw "probe exit $($p.ExitCode)"};Get-Content "$dir\stdout.log"|Select-String 'SYNC_PROFILE|SYNC_NETWORK|MATH_SMALL'
}
Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
New-Item -ItemType Directory -Force "$r\cache","$r\modules-A","$r\modules-$Candidate","$r\$Candidate-out"|Out-Null
Copy-Item "$base\modules\gfx1201\*.hsaco" "$r\modules-A" -Force;Copy-Item "$base\modules\gfx1201\*.hsaco" "$r\modules-$Candidate" -Force
Copy-Item "$r\gfx1201\A.hsaco" "$r\modules-A\deep_fast-packed-fast.hsaco" -Force;Copy-Item "$r\gfx1201\$Candidate.hsaco" "$r\modules-$Candidate\deep_fast-packed-fast.hsaco" -Force
if($Shape -eq '1088'){$w=1920;$ph=1088;$input="$data\fixture\processing1088.rgba32f";$flags=Get-Content "$data\fast1-1088.flags"}
else{$w=1600;$ph=960;$input='D:\DLSSNR-Lab\sync-network-gap-20261006\fixture\processing.rgba32f';$flags=Get-Content 'D:\DLSSNR-Lab\sync-network-gap-20261006\fast1.flags'}
[IO.File]::WriteAllLines("$r\$Candidate-out\flags-$Shape.txt",$flags+@('DLSS5_FAST_NUMERIC=1','DLSS5_MULTI_PASS=1','DLSS5_VIT_ADAPTIVE=0','DLSS5_TEMPORAL_HISTORY_EXPERIMENT=0'))
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{
 if($Candidate -eq 'B'){Probe "$r\small-probe.exe" "$r\gfx1201\score-probe.hsaco $r\gfx1201\den-probe.hsaco $r score-only" "$r\B-out\small"}
 else{Probe "$r\small-probe.exe" "$r\gfx1201\score-probe.hsaco $r\gfx1201\den-probe.hsaco $r" "$r\C-out\small"}
 for($slot=0;$slot -lt 4;$slot++){$side=if($slot -eq 1 -or $slot -eq 2){$Candidate}else{'A'};$dir="$r\$Candidate-out\$Shape-$slot";Probe "$r\benchmark.exe" "$base\assets $r\modules-$side $r\$Candidate-out\flags-$Shape.txt $input $dir 80 160 $w $ph" $dir}
}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force;'LOCK_RELEASED'}

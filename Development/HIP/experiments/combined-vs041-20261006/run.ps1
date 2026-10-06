param([ValidateSet('900','1080')][string]$Height='900',[ValidateSet(1,3)][int]$Pass=1,[ValidateSet(0,1)][int]$Predict=1,[int]$Frames=320,[int]$Round=1,[switch]$AllowPendingProduction)
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\combined-vs041-20261006'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle {& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game busy/failure'};if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'game running'};if(Get-Process|Where-Object {$_.ProcessName -match '^rtc_compile$'}){throw 'compiler active'}}
Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
New-Item -ItemType Directory -Force "$r\cache","$r\ABBA-$Height-MP$Pass-PRED$Predict-round$Round"|Out-Null
$baseflags=Get-Content "$r\base.flags"
# This manifest is supplied only after productioncandidate CPU/datafreeze; failclosed while pending.
$locked=Get-Content "$r\current-freeze.json" -Raw|ConvertFrom-Json
if($locked.freeze_status -ne 'validated' -and !($AllowPendingProduction -and $locked.freeze_status -eq 'source_locked_compat_pending')){throw 'current combination not frozen/validated'}
foreach($side in '041','current'){
 foreach($item in (Get-Content "$r\manifest-$side.json" -Raw|ConvertFrom-Json)){
  $path=Join-Path $r $item.path;if((Get-Item $path).Length -ne $item.bytes -or (Get-FileHash $path -Algorithm SHA256).Hash -ne $item.sha256){throw "artifact changed $path"}
 }
 if(Test-Path "$r\assets-common\temporal-history.txt"){throw 'unexpected legacy marker'}
}
if((Get-Item "$r\input.f16").Length -ne 7464960 -or (Get-FileHash "$r\input.f16").Hash -ne $locked.input_sha256){throw 'shared HDR input changed'}
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{
 for($slot=0;$slot -lt 4;$slot++){
  Idle;$side=if($slot -eq 1 -or $slot -eq 2){'current'}else{'041'};$dir="$r\ABBA-$Height-MP$Pass-PRED$Predict-round$Round\slot-$slot";if(Test-Path $dir){throw 'Existing measured slot; do not overwrite/replay'};New-Item -ItemType Directory $dir|Out-Null
  [IO.File]::WriteAllLines("$dir\flags.txt",$baseflags+@("DLSS5_NETWORK_HEIGHT=$Height",'DLSS5_NETWORK_1080_ROWS=1152','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_NET_TIMING=0','DLSS5_HIP_INPUT_POLL=0','DLSS5_HIP_SPAN_PROBE=0','DLSS5_GAME_PROBE=0','DLSS5_BLACK_PROBE=0',"DLSS5_MULTI_PASS=$Pass","DLSS5_MULTI_PASS_PREDICT=$Predict",'DLSS5_MULTI_PASS_SKIN_PROTECT=0','DLSS5_VIT_ADAPTIVE=0','DLSS5_TEMPORAL_HISTORY_EXPERIMENT=0','DLSS5_SKIP_BLOCKS=','DLSS5_LAB_SUBMIT_SINGLE=0','DLSS5_LAB_SUBMIT_PAIR=0','DLSS5_LAB_SUBMIT_UNTIMED_PAIR=0'))
  $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName="$r\benchmark-$side.exe";$psi.Arguments="$r\assets-common $dir\flags.txt $r\input.f16 $dir\frame $Frames 0 $r\modules-$side 0 1 0 0";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_') -or $key.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($key)}}
  $psi.EnvironmentVariables['TEMP']="$r\cache";$psi.EnvironmentVariables['TMP']="$r\cache";$psi.EnvironmentVariables['HIP_CACHE_DIR']="$r\cache"
  $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'probe start'};$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
  while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game started, own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'probe timeout'}}
  $p.WaitForExit();$out.Result|Set-Content "$dir\stdout.log";$err.Result|Set-Content "$dir\stderr.log";if($p.ExitCode){Get-Content "$dir\stderr.log" -Tail 6;throw "probe exit $($p.ExitCode), no repeat"};Get-Content "$dir\stdout.log" -Tail 3
 }
 foreach($name in 'frame-first.f16','frame.f16'){if((Get-FileHash "$r\ABBA-$Height-MP$Pass-PRED$Predict-round$Round\slot-0\$name").Hash -ne (Get-FileHash "$r\ABBA-$Height-MP$Pass-PRED$Predict-round$Round\slot-1\$name").Hash -or (Get-FileHash "$r\ABBA-$Height-MP$Pass-PRED$Predict-round$Round\slot-0\$name").Hash -ne (Get-FileHash "$r\ABBA-$Height-MP$Pass-PRED$Predict-round$Round\slot-2\$name").Hash -or (Get-FileHash "$r\ABBA-$Height-MP$Pass-PRED$Predict-round$Round\slot-0\$name").Hash -ne (Get-FileHash "$r\ABBA-$Height-MP$Pass-PRED$Predict-round$Round\slot-3\$name").Hash){throw 'full frame pixel mismatch'}}
 Get-FileHash "$r\input.f16","$r\benchmark-041.exe","$r\benchmark-current.exe","$r\ABBA-$Height-MP$Pass-PRED$Predict-round$Round\slot-0\frame.f16"|Select-Object Path,Hash|ConvertTo-Json|Set-Content "$r\ABBA-$Height-MP$Pass-PRED$Predict-round$Round\fixture-hashes.json"
}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force;'LOCK_RELEASED'}

param([ValidateSet('900','1080')][string]$Height='900')
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\pulse-production-20261006';$base='D:\DLSSNR-Lab\history-trial-041a-20261006'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle {& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game busy/failure'};if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'game running'};if(Get-Process|Where-Object {$_.ProcessName -match '^rtc_compile$'}){throw 'compiler active'}}
Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
New-Item -ItemType Directory -Force "$r\cache","$r\production-scope-$Height"|Out-Null
$baseflags=Get-Content 'D:\DLSSNR-Lab\sync-network-gap1080-20261006\fast1-1152.flags'
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{
 for($slot=0;$slot -lt 10;$slot++){
  Idle;$candidate=$slot%2;$kind=[int][Math]::Floor($slot/2);$multi=if($kind -eq 0){3}else{1};$history=if($kind -eq 1 -or $kind -eq 2){1}else{0};$frames=3;$dataGate=0;$reset=if($kind -eq 2){1}else{0};$graph=if($kind -eq 3){1}else{0};$resize=if($kind -eq 4){1}else{0};$pulse=if(!$candidate){'0'}elseif($kind -eq 4){'1'}else{'auto'};$dir="$r\production-scope-$Height\slot-$slot";if(Test-Path $dir){throw 'Existing measured slot; do not overwrite/replay'};New-Item -ItemType Directory $dir|Out-Null
  [IO.File]::WriteAllLines("$dir\flags.txt",$baseflags+@("DLSS5_NETWORK_HEIGHT=$Height",'DLSS5_NETWORK_1080_ROWS=1152','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_NET_TIMING=0','DLSS5_GAME_PROBE=0','DLSS5_FRAME_STATS=0','DLSS5_HIP_SPAN_PROBE=0','DLSS5_BLACK_PROBE=0','DLSS5_HIP_DUP_PREFIX=','DLSS5_HIP_DUP_COUNT=1',"DLSS5_MULTI_PASS=$multi",'DLSS5_MULTI_PASS_PREDICT=0','DLSS5_MULTI_PASS_SKIN_PROTECT=0','DLSS5_VIT_ADAPTIVE=0','DLSS5_TEMPORAL_HISTORY_EXPERIMENT=0','DLSS5_SKIP_BLOCKS=',"DLSS5_HIP_SUBMIT_PULSE=$pulse", "DLSS5_HIP_GRAPH=$graph", "DLSS5_HIP_PDL=$(if($graph){0}else{1})", "DLSS5_LAB_PULSE_RESIZE=$resize","DLSS5_LAB_PULSE_DATA_GATE=$dataGate",'DLSS5_RESIDUAL_RGB=1'))
  $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName="$r\benchmark-prod-scope.exe";$psi.Arguments="$base\assets $dir\flags.txt D:\DLSSNR-Lab\hip-backend\live-menu-before.f16 $dir\frame $frames $history $base\modules\gfx1201 $reset 0 0 0";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_') -or $key.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($key)}}
  $psi.EnvironmentVariables['TEMP']="$r\cache";$psi.EnvironmentVariables['TMP']="$r\cache";$psi.EnvironmentVariables['HIP_CACHE_DIR']="$r\cache"
  $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'probe start'};$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
  while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game started, own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'probe timeout'}}
  $p.WaitForExit();$out.Result|Set-Content "$dir\stdout.log";$err.Result|Set-Content "$dir\stderr.log";if($p.ExitCode){Get-Content "$dir\stderr.log" -Tail 6;throw "probe exit $($p.ExitCode), no repeat"};Get-Content "$dir\stdout.log" -Tail 3
 }
 foreach($even in 0,2,4,6,8){foreach($i in 0..2){if((Get-FileHash "$r\production-scope-$Height\slot-$even\frame-frame-$i.f16").Hash -ne (Get-FileHash "$r\production-scope-$Height\slot-$($even+1)\frame-frame-$i.f16").Hash){throw "scope gold mismatch $even/$($even+1) frame$i"}}}
 foreach($slot in 0..9){$dir="$r\production-scope-$Height\slot-$slot";$csv=Import-Csv "$dir\frame.csv";if($csv|Where-Object {$_.invalid -ne '0' -or $_.checked -ne '1'}){throw 'scope nonfinite/unread frame'};$log=Get-Content "$dir\stderr.log" -Raw;if($log -match 'FRAME_NET_GPU|hip_span probe enabled'){throw 'diagnostic activated'}
  $expected=if($slot -eq 3){1}elseif($slot -eq 5){3}elseif($slot -eq 9){1}else{0};$created=if($expected){1}else{0};$drain=if($expected){1}else{0}
  $pattern="submit_pulse resources create=$created create_ok=$created record=$expected record_ok=$expected destroy=$created destroy_ok=$created drain=$drain";$matches=[regex]::Matches($log,$pattern);$expectedInstances=if($slot -ge 8){3}else{1};if($matches.Count -ne $expectedInstances){throw "scope resource/count mismatch slot$slot expectedinstances$expectedInstances"}
  if($slot -ge 8 -and (Get-Content "$dir\stdout.log" -Raw) -notmatch 'PULSE_RESIZE rebuilt frame=2 requested_height=900'){throw 'real Frame rebuild not observed'}
 }
 'PRODUCTION_SCOPE_PASS MP3/history-used/reset/graphPDL0/explicit1_realFrameRebuild_900_1152_900/rawsamefinite'
 Get-FileHash "$r\benchmark-prod-scope.exe",'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16'|Select-Object Path,Hash|ConvertTo-Json|Set-Content "$r\production-scope-$Height\fixture-hashes.json"
}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force;'LOCK_RELEASED'}

param([ValidateSet('900','1080')][string]$Height='900')
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\framework-single-event-20261006';$base='D:\DLSSNR-Lab\history-trial-041a-20261006'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle {& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game busy/failure'};if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'game running'};if(Get-Process|Where-Object {$_.ProcessName -match '^rtc_compile$'}){throw 'compiler active'}}
Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
New-Item -ItemType Directory -Force "$r\cache","$r\app-boundary-data-$Height"|Out-Null
$baseflags=Get-Content 'D:\DLSSNR-Lab\sync-network-gap1080-20261006\fast1-1152.flags'
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{
 for($slot=0;$slot -lt 6;$slot++){
  Idle;$candidate=$slot%2;$multi=if($slot -eq 2 -or $slot -eq 3){3}else{1};$history=if($slot -ge 4){1}else{0};$frames=if($slot -lt 2){5}else{3};$dataGate=if($slot -lt 2){1}else{0};$dir="$r\app-boundary-data-$Height\slot-$slot";if(Test-Path $dir){throw 'Existing measured slot; do not overwrite/replay'};New-Item -ItemType Directory $dir|Out-Null
  [IO.File]::WriteAllLines("$dir\flags.txt",$baseflags+@("DLSS5_NETWORK_HEIGHT=$Height",'DLSS5_NETWORK_1080_ROWS=1152','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_NET_TIMING=0','DLSS5_GAME_PROBE=0','DLSS5_FRAME_STATS=0','DLSS5_HIP_SPAN_PROBE=0','DLSS5_BLACK_PROBE=0','DLSS5_HIP_DUP_PREFIX=','DLSS5_HIP_DUP_COUNT=1',"DLSS5_MULTI_PASS=$multi",'DLSS5_MULTI_PASS_PREDICT=0','DLSS5_MULTI_PASS_SKIN_PROTECT=0','DLSS5_VIT_ADAPTIVE=0','DLSS5_TEMPORAL_HISTORY_EXPERIMENT=0','DLSS5_SKIP_BLOCKS=',"DLSS5_LAB_SUBMIT_SINGLE=$candidate","DLSS5_LAB_PULSE_DATA_GATE=$dataGate",'DLSS5_RESIDUAL_RGB=1'))
  $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName="$r\benchmark-single-app.exe";$psi.Arguments="$base\assets $dir\flags.txt D:\DLSSNR-Lab\hip-backend\live-menu-before.f16 $dir\frame $frames $history $base\modules\gfx1201 0 0 0 0";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_') -or $key.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($key)}}
  $psi.EnvironmentVariables['TEMP']="$r\cache";$psi.EnvironmentVariables['TMP']="$r\cache";$psi.EnvironmentVariables['HIP_CACHE_DIR']="$r\cache"
  $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'probe start'};$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
  while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game started, own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'probe timeout'}}
  $p.WaitForExit();$out.Result|Set-Content "$dir\stdout.log";$err.Result|Set-Content "$dir\stderr.log";if($p.ExitCode){Get-Content "$dir\stderr.log" -Tail 6;throw "probe exit $($p.ExitCode), no repeat"};Get-Content "$dir\stdout.log" -Tail 3
 }
 foreach($pair in @(@(0,1,5),@(2,3,3),@(4,5,3))){for($i=0;$i -lt $pair[2];$i++){if((Get-FileHash "$r\app-boundary-data-$Height\slot-$($pair[0])\frame-frame-$i.f16").Hash -ne (Get-FileHash "$r\app-boundary-data-$Height\slot-$($pair[1])\frame-frame-$i.f16").Hash){throw "gold pair $($pair[0])/$($pair[1]) frame$i mismatch"}}}
 foreach($slot in 0,1){$dir="$r\app-boundary-data-$Height\slot-$slot";$zero=(Get-FileHash "$dir\frame-frame-0.f16").Hash;foreach($i in 1,3,4){if((Get-FileHash "$dir\frame-frame-$i.f16").Hash -ne $zero){throw 'cold/warm/return mismatch'}};if((Get-FileHash "$dir\frame-frame-2.f16").Hash -eq $zero){throw 'changed HDR+seed fixture did not change output'}}
 foreach($slot in 0..5){$dir="$r\app-boundary-data-$Height\slot-$slot";$csv=Import-Csv "$dir\frame.csv";if($csv|Where-Object {$_.invalid -ne '0' -or $_.checked -ne '1'}){throw 'nonfinite/unread data frame'};$log=Get-Content "$dir\stderr.log" -Raw;if($log -notmatch 'APP_DIAGNOSTIC_RECEIPT timer_on=0 timer_creates=0 timer_records=0 timer_queries=0 span_probe=0 poll_records=0'){throw 'diagnostic event/query active'}
  $expectedRecords=if($slot -eq 1){5}elseif($slot -eq 5){1}else{0};$expectedHandles=if($slot -eq 1 -or $slot -eq 5){1}else{0};$expectedDrain=if($expectedRecords){1}else{0};if($log -notmatch "APP_PULSE_RECEIPT create=$expectedHandles create_ok=$expectedHandles record=$expectedRecords record_ok=$expectedRecords destroy=$expectedHandles destroy_ok=$expectedHandles drain=$expectedDrain"){throw "resource/record count mismatch slot$slot"}}
 $mainLog=Get-Content "$r\app-boundary-data-$Height\slot-1\stderr.log" -Raw
 $pattern='APP_PULSE_RECEIPT.*pdl_calls=(\d+) site_visits=5 attempts=5 accepted=5 reject_mask=0'
 if($mainLog -notmatch $pattern){throw 'actual point attempts/accepted mismatch'};$lifetimePdl=[int64]$Matches[1]
 if($mainLog -notmatch 'site=C512_encoder_start preceding=ordered_Down_c256 launch_mode=hipModuleLaunchKernel mode=timed_single current_anyorder=0.*frame_prefix_pdl=(\d+)'){throw 'first actual boundary trace missing'};$firstPrefixPdl=[int64]$Matches[1]
 if($Height -eq '900' -and ($lifetimePdl -le 0 -or $firstPrefixPdl -le 0)){throw '900 PDL1 baseline did not actually launch AnyOrder before marker'}
 if($Height -eq '1080' -and ($lifetimePdl -ne 0 -or $firstPrefixPdl -ne 0)){throw '1152 expected actual ordered profile pdl0'}
 $mpLog=Get-Content "$r\app-boundary-data-$Height\slot-3\stderr.log" -Raw;if($mpLog -notmatch 'initialized=0 active=0 reason=init-scope-reject init_reject_mask=128'){throw 'MP3 scope-reject metadata missing'}
 $histLog=Get-Content "$r\app-boundary-data-$Height\slot-5\stderr.log" -Raw;if($histLog -notmatch 'reason=frame-scope-fallback reject_mask=1'){throw 'history-frame fallback metadata missing'}
 'DATA_GATE_PASS cold/warm/changed_HDR_seed7/return/rawsamefinite; MP3 and history-frame fallback; PDL baseline unchanged'
 Get-FileHash 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16',"$r\benchmark-single-app.exe"|Select-Object Path,Hash|ConvertTo-Json|Set-Content "$r\app-boundary-data-$Height\fixture-hashes.json"
}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force;'LOCK_RELEASED'}

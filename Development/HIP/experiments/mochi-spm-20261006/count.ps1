$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$r='D:\DLSSNR-Lab\mochi-spm-20261006';$fixtureRoot='D:\DLSSNR-Lab\sync-network-gap1080-20261006';$modules='D:\DLSSNR-Lab\combined-vs041-20261006\modules-current';$base='D:\DLSSNR-Lab\history-trial-041a-20261006';$mz='D:\DLSSNR-Lab\competitor-timing-20260930\mz';$lock='D:\DLSSNR-Lab\gpu.lock'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64'
function CheckGame {if(Get-Process | Where-Object {$_.ProcessName -match $games}){throw 'Game running; do not use GPU'}}
CheckGame
if(Get-Process | Where-Object {$_.ProcessName -match 'benchmark|nr_graph|rtc_compile|frame-probe|integrated-probe'}){throw 'Another GPU/compile job present'}
if((Get-PSDrive D).Free -lt 100GB){throw 'D writable/cache free<100GB'}
if((Get-FileHash "$mz\nr_graph.exe").Hash.ToLower() -ne '8ad3ac1cfd5d83f58fb9a223e21d7a970118518839bada3abcaba66af5e8d153'){throw 'Old mochi exe identity drift'}
if((Get-FileHash "$mz\dlssnr.bin").Hash.ToLower() -ne '2b41c888cf4155b8958c665ba64018ab0bd25c85fc71a2b6db86d0d04d1f7fbd'){throw 'Old mochi model identity drift'}
New-Item -ItemType Directory -Force $r,"$r\cache" | Out-Null
Copy-Item "$mz\pc.bin" "$r\mochi-cache.bin" -Force
$owner=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);$p=$null
try {
 $tag=[Text.Encoding]::UTF8.GetBytes('sync-network-gap1080-20261006');$owner.Write($tag,0,$tag.Length);CheckGame
 $manifest=@(Get-ChildItem "$modules" -File | ForEach-Object {@{name=$_.Name;bytes=$_.Length;sha256=(Get-FileHash $_.FullName).Hash}})
 $manifest | ConvertTo-Json -Depth 4 | Set-Content "$r\module-hashes.json"
 Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion | ConvertTo-Json | Set-Content "$r\driver.json"
 $before=@(Get-ChildItem $mz -File -Recurse | ForEach-Object { $_.FullName+'|'+$_.Length+'|'+$_.LastWriteTimeUtc.Ticks})
 $schedule=@('M','M');$i=0
 foreach($ph in @(1088)){
 foreach($kind in $schedule){
  CheckGame;$label=('{0}-{1:D2}-{2}' -f $ph,$i,$kind);$out="$r\$label";New-Item -ItemType Directory -Force $out | Out-Null
  $psi=New-Object Diagnostics.ProcessStartInfo;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;$psi.WorkingDirectory=$r
  foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_') -or $key.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($key)}}
  $psi.EnvironmentVariables['TEMP']="$r\cache";$psi.EnvironmentVariables['TMP']="$r\cache";$psi.EnvironmentVariables['HIP_CACHE_DIR']="$r\cache"
  if($kind -eq 'M'){$psi.FileName="$mz\nr_graph.exe";$psi.Arguments="--plan $mz\plan-1920x1080.txt --model-pack $mz\dlssnr.bin --spv-dir $mz\spv --host-boundary --reuse --source-width 1920 --source-height 1080 --accumulation fp32 --pipeline-cache $r\mochi-cache.bin --warmup 80 --repeats 2 --chunk 1 --style 1 --img-seed 0 --in-image $fixtureRoot\fixture\valid.rgba32f --out-image $out\final.rgba32f"}
  else {$fast=if($kind -eq 'F0'){0}else{1};$psi.FileName="$r\benchmark.exe";$psi.Arguments="$base\assets $modules $fixtureRoot\fast$fast-$ph.flags $fixtureRoot\fixture\processing$ph.rgba32f $out 80 160 $ph"}
  $p=New-Object Diagnostics.Process;$p.StartInfo=$psi;if(!$p.Start()){throw 'Start failed'};$std=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
  while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process | Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'Game started; stopped ONLY own probe'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 45){$p.Kill();throw 'Own probe timeout'}}
  $p.WaitForExit();$std.Result | Set-Content "$out\stdout.log";$err.Result | Set-Content "$out\stderr.log";if($p.ExitCode -ne 0){throw "Probe failed $label exit$($p.ExitCode); bad batch stopped"}
  if(!(Get-Content "$out\stdout.log" | Select-String '^123 dispatches, one submit:')){throw 'Actual step count changed'}
  Get-Content "$out\stdout.log" | Select-String 'SYNC_NETWORK|SYNC_PROFILE|one submit|measurement wall|pre conditioning|working extent'
  $i++
 }
 }
 $after=@(Get-ChildItem $mz -File -Recurse | ForEach-Object { $_.FullName+'|'+$_.Length+'|'+$_.LastWriteTimeUtc.Ticks})
 $delta=@(Compare-Object $before $after);@{pass=($delta.Count -eq 0);changes=$delta} | ConvertTo-Json -Depth 4 | Set-Content "$r\old-assets-unmodified.json";if($delta.Count){throw 'Old mochi files changed'}
 $a=(Get-FileHash "$r\1088-00-M\final.rgba32f").Hash;$b=(Get-FileHash "$r\1088-01-M\final.rgba32f").Hash;$old=(Get-FileHash 'D:\DLSSNR-Lab\fresh-mochi1088-20261006\1088-01-M\final.rgba32f').Hash
 if($a -ne $b -or $a -ne $old){throw 'M own raw reference differs/repeats mismatch'}
 @{same=$true;reference_sha=$a;actual_step_count=123;step_count_basis='Each real stdout must independently report123; source maps eachStep to1dispatch';global_initialization_offset_verified=$false}|ConvertTo-Json|Set-Content "$r\reference.json"
 'MOCHI_OWN_REFERENCE_DONE; no capture/no clocks changes'

}finally{if($p -and !$p.HasExited){$p.Kill()};$owner.Dispose();Remove-Item $lock -Force;'LOCK_RELEASED'}

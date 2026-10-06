$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$r='D:\DLSSNR-Lab\mochi-vit-score-control-20261006';$mz='D:\DLSSNR-Lab\competitor-timing-20260930\mz';$fixture='D:\DLSSNR-Lab\sync-network-gap1080-20261006\fixture\valid.rgba32f';$lock='D:\DLSSNR-Lab\gpu.lock';$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64'
function CheckGame{if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'Game active'}}
CheckGame
if(Get-Process|Where-Object {$_.ProcessName -match 'benchmark|nr_graph|rtc_compile|pure_fullnn|gold'}){throw 'Experiment active'}
if((Get-PSDrive D).Free -lt 100GB){throw 'Free D<100GB'}
if((Get-FileHash "$mz\nr_graph.exe").Hash.ToLower() -ne '8ad3ac1cfd5d83f58fb9a223e21d7a970118518839bada3abcaba66af5e8d153'){throw 'locked exe drift'}
if((Get-FileHash "$mz\dlssnr.bin").Hash.ToLower() -ne '2b41c888cf4155b8958c665ba64018ab0bd25c85fc71a2b6db86d0d04d1f7fbd'){throw 'model drift'}
if((Get-FileHash $fixture).Hash.ToLower() -ne '17b2e09bf9757a5a98fbd65a08f618100ec42f4d7abb7036cb03cb19e3ae4e2a'){throw 'common valid input drift'}
if((Get-FileHash "$mz\plan-1920x1080.txt").Hash.ToLower() -ne '93f8ab6976d235c7383e17f9c67ba7ba694fd440d7a0238b19516ad75761f2e0'){throw 'plan drift'}
if(Get-Process|Where-Object {$_.ProcessName -eq 'RadeonDeveloperPanelCLI'}){throw 'capture controller active'}
$m=Get-Content "$r\overlay-manifest.json" -Raw|ConvertFrom-Json
foreach($e in $m.rows){if((Get-FileHash "$mz\spv\$($e.path)").Hash.ToLower() -ne $e.oldSHA){throw 'old SPVtree drift'};if((Get-FileHash "$r\overlay-spv\$($e.path)").Hash.ToLower() -ne $e.newSHA){throw 'new SPVtree drift'}}
$out="$r\diag-1";if(Test-Path $out){throw 'refuse overwrite'};New-Item -ItemType Directory -Force $out,"$out\cache"|Out-Null
$owner=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);$p=$null
try{
 foreach($side in @('old','new')){foreach($i in 0..1){
  CheckGame;$d="$out\$side-$i";New-Item -ItemType Directory $d|Out-Null;Copy-Item "$mz\pc.bin" "$d\pc.bin"; $spv=if($side -eq 'old'){"$mz\spv"}else{"$r\overlay-spv"}
  $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName="$mz\nr_graph.exe";$psi.Arguments="--plan $mz\plan-1920x1080.txt --model-pack $mz\dlssnr.bin --spv-dir $spv --host-boundary --reuse --source-width 1920 --source-height 1080 --accumulation fp32 --pipeline-cache $d\pc.bin --warmup 80 --repeats 2 --chunk 1 --style 1 --img-seed 0 --in-image $fixture --out-image $d\final.rgba32f";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  foreach($k in @($psi.EnvironmentVariables.Keys)){if($k.StartsWith('DLSS5_') -or $k.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($k)}}
  $psi.EnvironmentVariables['TEMP']="$out\cache";$psi.EnvironmentVariables['TMP']="$out\cache"
  $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'start'};$std=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
  while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game began own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'own timeout'}}
  $p.WaitForExit();$std.Result|Set-Content "$d\stdout.log";$err.Result|Set-Content "$d\stderr.log";if($p.ExitCode -ne 0){throw 'diagnostic failed'}
 }}
 foreach($side in @('old','new')){if((Get-FileHash "$out\$side-0\final.rgba32f").Hash -ne (Get-FileHash "$out\$side-1\final.rgba32f").Hash){throw 'own crossprocess repeat mismatch'}}
 'OWN_CROSSPROCESS_REPEAT_PASS; relative-old RGB/finite CPU gate pending; no performance claim'
}finally{if($p -and !$p.HasExited){$p.Kill()};$owner.Dispose();Remove-Item $lock -Force;'LOCK_RELEASED'}

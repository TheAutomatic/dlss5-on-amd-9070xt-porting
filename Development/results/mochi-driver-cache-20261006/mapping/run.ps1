$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$r='D:\DLSSNR-Lab\mochi-pipeline-map-20261006';$base='D:\DLSSNR-Lab\history-trial-041a-20261006';$mz='D:\DLSSNR-Lab\competitor-timing-20260930\mz';$lock='D:\DLSSNR-Lab\gpu.lock'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64'
function CheckGame {if(Get-Process | Where-Object {$_.ProcessName -match $games}){throw 'Game running; do not use GPU'}}
CheckGame
if(Get-Process | Where-Object {$_.ProcessName -match 'benchmark|nr_graph|rtc_compile|frame-probe|integrated-probe'}){throw 'Another GPU/compile job present'}
if((Get-PSDrive D).Free -lt 100GB){throw 'D writable/cache free<100GB'}
if((Get-FileHash "$mz\nr_graph.exe").Hash.ToLower() -ne '8ad3ac1cfd5d83f58fb9a223e21d7a970118518839bada3abcaba66af5e8d153'){throw 'Old mochi exe identity drift'}
if((Get-FileHash "$mz\dlssnr.bin").Hash.ToLower() -ne '2b41c888cf4155b8958c665ba64018ab0bd25c85fc71a2b6db86d0d04d1f7fbd'){throw 'Old mochi model identity drift'}

if((Get-FileHash "$mz\spv\g_attn.spv").Hash.ToLower() -ne '2b5c7152666df3d68e31a53881cb71f0f6bb2637c3055ad0ffb81f297a5b1ccc'){throw 'SPV drift attn'}
if((Get-FileHash "$mz\spv\g_vitattn.spv").Hash.ToLower() -ne '8993390ab9316895daf19c3c9ba669b984301c4a1624e87901fbcbf2e46634b1'){throw 'SPV drift vitattn'}
New-Item -ItemType Directory -Force $r | Out-Null
$owner=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);$p=$null
try {
 foreach($target in @('attn','vitattn')){
  CheckGame;$cache="$r\$target-only.bin";if(Test-Path $cache){throw 'isolated cache exists'}
  $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName="$r\create.exe";$psi.Arguments="$target $mz\spv\g_$target.spv $cache";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_') -or $key.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($key)}}
  $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'start'};$std=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
  while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game began stopped own creator'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 90){$p.Kill();throw 'own compile timeout'}}
  $p.WaitForExit();$std.Result|Set-Content "$r\$target.stdout.log";$err.Result|Set-Content "$r\$target.stderr.log";Get-Content "$r\$target.stdout.log";if($p.ExitCode -ne 0){throw 'target compile failed'}
 }
}finally{if($p -and !$p.HasExited){$p.Kill()};$owner.Dispose();Remove-Item $lock -Force;'LOCK_RELEASED'}

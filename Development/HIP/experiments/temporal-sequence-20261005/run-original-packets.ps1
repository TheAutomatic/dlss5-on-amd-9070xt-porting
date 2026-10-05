$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Oracle\temporal-20261005'
$games='SB-Win64|Onimusha|re9|Magpie|SandFall|Wuthering|Client-Win64'
function AssertIdle {if(Get-Process | Where-Object {$_.ProcessName -match $games}){throw 'Game running; no GPU probe'}}
AssertIdle
if((Get-PSDrive D).Free -lt 100GB){throw 'D drive below 100GB free'}
$plugin='D:\DLSSNR-Oracle\issue13\nvngx_dlssnr.dll'
if((Get-FileHash $plugin).Hash.ToLower() -ne 'e16bcf15e16e13f527491cdf7845b2fe6521a738d8f7c9c721866a8496e1fc8e'){throw 'Original plugin fingerprint mismatch'}
New-Item -ItemType Directory -Force $root | Out-Null
Copy-Item D:\DLSSNR-Oracle\ngx-temporal-packets.exe "$root\ngx-temporal-packets.exe" -Force
$lock='D:\DLSSNR-Oracle\gpu.lock'
$owner=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try {
 $tag=[Text.Encoding]::UTF8.GetBytes('temporal-original-packets-20261005');$owner.Write($tag,0,$tag.Length)
 AssertIdle
 $meta=@{plugin_sha256=(Get-FileHash $plugin).Hash;core_sha256=(Get-FileHash 'D:\DLSSNR-Oracle\issue13\core615.dll').Hash;exe_sha256=(Get-FileHash "$root\ngx-temporal-packets.exe").Hash;input_source='issue13 existing encoded pair; unrelated to 111.mp4';reset=@(1,0);seed='original, observed not patched';motion='separate zero RG16F';depth='separate R32F constant1';width=1920;height=1080}
 $meta | ConvertTo-Json -Depth 4 | Set-Content "$root\provenance.json"
 $psi=New-Object Diagnostics.ProcessStartInfo
 $psi.FileName="$root\ngx-temporal-packets.exe"
 $psi.Arguments="D:\DLSSNR-Oracle\issue13\core615.dll D:\DLSSNR-Oracle\issue13 D:\DLSSNR-Oracle\issue13\inputs $root\packets"
 $psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 $p=New-Object Diagnostics.Process;$p.StartInfo=$psi
 if(!$p.Start()){throw 'Probe did not start'}
 $out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
 while(!$p.HasExited){
  Start-Sleep -Milliseconds 250
  if([DateTime]::UtcNow -ge $next){if(Get-Process | Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'Game started; only own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)}
  if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'Bounded probe timeout'}
 }
 $p.WaitForExit();$out.Result | Set-Content "$root\eval.log";$err.Result | Set-Content "$root\stderr.log"
 if($p.ExitCode -ne 0){throw "Probe exit $($p.ExitCode); see eval.log"}
 Get-Content "$root\eval.log" | Select-String 'INIT=|CAPS=|CREATE18=|EVAL'
 Get-Item "$root\packets\launch-observe.txt" | Select-Object Length
} finally {$owner.Dispose();Remove-Item $lock -Force}

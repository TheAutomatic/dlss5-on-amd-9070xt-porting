param([switch]$SequenceOnly)
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\post-history-gate-20261005';$lock='D:\DLSSNR-Lab\gpu.lock'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function AssertIdle {
 & D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game-check busy/failure'}
 if(Get-Process | Where-Object {$_.ProcessName -match $games}){throw 'Game process running'}
}
AssertIdle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try {
 $tag=[Text.Encoding]::UTF8.GetBytes('temporal-sequence-20261005');$f.Write($tag,0,$tag.Length)
 function Probe($exe,$arguments,$label){
  AssertIdle;$psi=New-Object Diagnostics.ProcessStartInfo;$psi.FileName=$exe;$psi.WorkingDirectory=$r;$psi.Arguments=$arguments
  $psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  $p=New-Object Diagnostics.Process;$p.StartInfo=$psi;if(!$p.Start()){throw 'Process start failed'}
  $out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
  while(!$p.HasExited){Start-Sleep -Milliseconds 250;if([DateTime]::UtcNow -ge $next){if(Get-Process | Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'Game started; own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 120){$p.Kill();throw 'Bounded probe timeout'}}
  $p.WaitForExit();$out.Result|Set-Content "$r\$label.log";$err.Result|Set-Content "$r\$label.err"
  Get-Content "$r\$label.log" -Tail 6
  if($p.ExitCode -ne 0){Get-Content "$r\$label.err" -Tail 6;throw "$label exit $($p.ExitCode)"}
 }
 if(!$SequenceOnly){Probe "$r\warp-probe.exe" "$r\warp-gfx1201.hsaco $r\gate-gfx1201.hsaco D:\DLSSNR-Lab\zero-copy-io-20260928\assets\normalized-output.f32 $r\native-sigmoid.f32 $r\sequence-gold" 'warp-gold'}
 Probe "$r\sequence.exe" "D:\DLSSNR-Lab\zero-copy-io-20260928\assets $r\sequence-HIP\gfx1201 $r\sequence-flags.txt $r\warp-gfx1201.hsaco $r\gate-gfx1201.hsaco $r\native-sigmoid.f32 $r\sequence-small" 'sequence-small'
 Probe "$r\sequence.exe" "D:\DLSSNR-Lab\zero-copy-io-20260928\assets $r\sequence-HIP\gfx1201 $r\sequence-flags.txt $r\warp-gfx1201.hsaco $r\gate-gfx1201.hsaco $r\native-sigmoid.f32 $r\sequence-1080 full" 'sequence-1080'
} finally {$f.Dispose();Remove-Item $lock -Force}

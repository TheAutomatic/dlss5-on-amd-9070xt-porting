$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\vit-math-stair-20261006'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle { & D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game busy/failure'};if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'game running'} }
Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{
 $env:RTC_EXTRA_OPTS='-ffp-contract=off'
 foreach($arch in 'gfx1201','gfx1200'){
  New-Item -ItemType Directory -Force "$r\$arch"|Out-Null
  foreach($name in 'A','B','C','score-probe','den-probe'){
   Idle;$psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName='D:\DLSSNR-Lab\release-041\payload\rtc_compile.exe';$psi.Arguments="$r\$arch\$name.hsaco $r\$name.hip comgr $arch";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
   $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'compile start'};$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
   while(!$p.HasExited){Start-Sleep -Milliseconds 250;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game started, own compiler stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 120){$p.Kill();throw 'compile timeout'}}
   $p.WaitForExit();$out.Result|Set-Content "$r\$arch\$name.log";$err.Result|Set-Content "$r\$arch\$name.err";if($p.ExitCode){Get-Content "$r\$arch\$name.err";throw "compile $name/$arch failed"};"COMPILED $arch $name"
  }
 }
}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force;'LOCK_RELEASED'}

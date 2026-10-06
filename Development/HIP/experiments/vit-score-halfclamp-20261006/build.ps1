$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\vit-score-halfclamp-20261006';$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle {if(Get-Process | Where-Object {$_.ProcessName -match $games}){throw 'game running'}; & D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game busy/failure'}}
Idle;if((Get-PSDrive D).Free -lt 100GB){throw 'D free<100GB'}
if(Get-Process | Where-Object {$_.ProcessName -match 'rtc_compile|benchmark|nr_graph|hosttrial'}){throw 'Other compile/GPU job present'}
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);$p=$null
try{
 $tag=[Text.Encoding]::UTF8.GetBytes('B2-CPU-COMGR21');$owner.Write($tag,0,$tag.Length);$env:RTC_EXTRA_OPTS='-ffp-contract=off'
 foreach($arch in 'gfx1201','gfx1200'){
  New-Item -ItemType Directory -Force "$r\$arch"|Out-Null
  foreach($name in 'B2','score-probe'){
   Idle;$si=New-Object Diagnostics.ProcessStartInfo;$si.FileName='D:\DLSSNR-Lab\release-041\payload\rtc_compile.exe';$si.Arguments="$r\$arch\$name.hsaco $r\$name.hip comgr $arch";$si.WorkingDirectory=$r;$si.UseShellExecute=$false;$si.RedirectStandardOutput=$true;$si.RedirectStandardError=$true;$p=New-Object Diagnostics.Process;$p.StartInfo=$si;$p.Start()|Out-Null;$o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
   while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process | Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game started; only own compiler stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 90){$p.Kill();throw 'own compiler timeout'}}
   $p.WaitForExit();$o.Result|Set-Content "$r\$arch\$name.log";$e.Result|Set-Content "$r\$arch\$name.err";if($p.ExitCode){Get-Content "$r\$arch\$name.err";throw 'compile failed'};"COMPILED $arch $name"
  }
 }
}finally{if($p -and !$p.HasExited){$p.Kill()};$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force;'LOCK_RELEASED'}

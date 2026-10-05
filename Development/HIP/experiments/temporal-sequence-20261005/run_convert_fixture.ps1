$ErrorActionPreference='Stop'
$r='D:\DLSSNR-Lab\temporal-replay-contract-20261006'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle { & D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game-check busy/failure'};if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'game running'} }
Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
$lock=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{
 foreach($round in 0,1){
  Idle;$config=Get-Content "$r\fixture-config.txt"; $config=$config -replace 'ROUND',"$round";[IO.File]::WriteAllLines("$r\config-$round.txt",$config)
  $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName="$r\replay-convert.exe";$psi.Arguments="$r\config-$round.txt";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'start'};$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
  while(!$p.HasExited){Start-Sleep -Milliseconds 250;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game started, only own converter stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 120){$p.Kill();throw 'converter timeout'}}
  $p.WaitForExit();$out.Result|Set-Content "$r\convert-$round.log";$err.Result|Set-Content "$r\convert-$round.err";if($p.ExitCode){Get-Content "$r\convert-$round.err";throw "convert exit $($p.ExitCode)"}
 }
 foreach($name in 'encoded','motion','coordinates'){if((Get-FileHash "$r\$name-0.f32").Hash -ne (Get-FileHash "$r\$name-1.f32").Hash){throw "$name repeat mismatch"}}
 # Compile only isolated experimental warp module, then validate native FP16 surface gold.
 $env:RTC_EXTRA_OPTS='-ffp-contract=off'
 & D:\DLSSNR-Lab\release-041\payload\rtc_compile.exe "$r\warp.hsaco" "$r\warp.hip" comgr gfx1201 *> "$r\warp-compile.log"
 if($LASTEXITCODE){Get-Content "$r\warp-compile.log";throw 'warp compile'}
 Idle
 & "$r\store-probe.exe" "$r\warp.hsaco" "$r\store-gold" > "$r\store.log" 2> "$r\store.err"
 if($LASTEXITCODE){Get-Content "$r\store.log","$r\store.err";throw 'store gold'}
 # Cold module loading is bounded by the same game watchdog as conversion.
 $config=Get-Content 'D:\DLSSNR-Lab\post-history-gate-20261005\sequence-flags.txt'
 [IO.File]::WriteAllLines("$r\sequence-flags.txt",$config+@('DLSS5_NETWORK_HEIGHT=720','DLSS5_NETWORK_1080_ROWS=1152'))
 New-Item -ItemType Directory -Force "$r\sequence"|Out-Null
 Copy-Item 'D:\DLSSNR-Lab\post-history-gate-20261005\post70-history-head.f16' "$r\sequence\post70-history-head.f16"
 [IO.File]::WriteAllLines("$r\prepared.tsv",@("0`t1280`t720`t768`t1`t1`t$r\encoded-0.f32`t$r\coordinates-0.f32","1`t1280`t720`t768`t0`t1`t$r\encoded-1.f32`t$r\coordinates-1.f32"))
 Idle
 $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName="$r\sequence.exe";$psi.Arguments="D:\DLSSNR-Lab\zero-copy-io-20260928\assets D:\DLSSNR-Lab\post-history-gate-20261005\sequence-HIP\gfx1201 $r\sequence-flags.txt $r\warp.hsaco D:\DLSSNR-Lab\post-history-gate-20261005\gate-gfx1201.hsaco D:\DLSSNR-Lab\post-history-gate-20261005\native-sigmoid.f32 $r\sequence prepared $r\prepared.tsv";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'sequence start'};$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
 while(!$p.HasExited){Start-Sleep -Milliseconds 250;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game started, only own sequence stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 180){$p.Kill();throw 'sequence timeout'}}
 $p.WaitForExit();$out.Result|Set-Content "$r\sequence.log";$err.Result|Set-Content "$r\sequence.err";if($p.ExitCode){Get-Content "$r\sequence.err" -Tail 6;throw 'sequence gate failed'}
 Get-Content "$r\store.log","$r\sequence.log"
 Get-FileHash "$r\encoded-0.f32","$r\motion-0.f32","$r\color.raw","$r\motion.raw","$r\replay-convert.exe" | Select-Object Path,Hash | ConvertTo-Json | Set-Content "$r\fixture-hashes.json"
 Get-Content "$r\convert-0.log","$r\receipt-0.txt"
}finally{$lock.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}

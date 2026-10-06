param([switch]$FinishOnly)
$ErrorActionPreference='Stop'
$r='D:\DLSSNR-Lab\history-trial-041a-20261006'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle { & D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game-check busy/failure'};if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'game running'} }
function Probe($exe,$arguments,$label){
 Idle;$psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=$exe;$psi.Arguments=$arguments;$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'probe start'};$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
 while(!$p.HasExited){Start-Sleep -Milliseconds 250;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game started, own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 240){$p.Kill();throw 'probe timeout'}}
 $p.WaitForExit();$out.Result|Set-Content "$r\$label.log";$err.Result|Set-Content "$r\$label.err";if($p.ExitCode){Get-Content "$r\$label.err" -Tail 8;throw "$label exit $($p.ExitCode)"}
 Get-Content "$r\$label.log" -Tail 12
}
New-Item -ItemType Directory -Force "$r\assets","$r\modules\gfx1201","$r\modules\gfx1200","$r\reference"|Out-Null
# Isolated copies of lab input/weights, not player assets or a game installation.
Get-ChildItem 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' -File|Where-Object {$_.Extension -in @('.f32','.f16','.fp8','.bin')}|ForEach-Object {if(!(Test-Path "$r\assets\$($_.Name)")){Copy-Item $_.FullName "$r\assets\$($_.Name)"}}
Copy-Item 'D:\DLSSNR-Lab\post-history-gate-20261005\post70-history-head.f16' "$r\assets\post70-history-head.f16" -Force
Copy-Item 'D:\DLSSNR-Lab\post-history-gate-20261005\native-sigmoid.f32' "$r\assets\native-temporal-sigmoid.f32" -Force
Copy-Item 'D:\DLSSNR-Lab\post-history-gate-20261005\sequence-HIP\gfx1201\*.hsaco' "$r\modules\gfx1201" -Force
# gfx1201 default rows remain unchanged; independent reference uses a same-math feature tap alias.
Copy-Item "$r\modules\gfx1201\*.hsaco" "$r\reference" -Force
Copy-Item "$r\modules\gfx1201\c32-wave1-temporal-fast.hsaco" "$r\reference\c32-wave1-fast.hsaco" -Force
Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
$lock=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{
 $base=Get-Content 'D:\DLSSNR-Lab\post-history-gate-20261005\sequence-flags.txt'
 $env:RTC_EXTRA_OPTS='-ffp-contract=off'
 if(!$FinishOnly){foreach($arch in 'gfx1201','gfx1200'){Probe 'D:\DLSSNR-Lab\release-041\payload\rtc_compile.exe' "$r\modules\$arch\temporal-history.hsaco $r\temporal-history.hip comgr $arch" "compile-$arch"}
 $base=Get-Content 'D:\DLSSNR-Lab\post-history-gate-20261005\sequence-flags.txt'
 [IO.File]::WriteAllLines("$r\flags.txt",$base+@('DLSS5_NETWORK_HEIGHT=720','DLSS5_NETWORK_1080_ROWS=1152','DLSS5_TEMPORAL_HISTORY_EXPERIMENT=1','DLSS5_TEMPORAL_MV_UNJITTERED=1'))
 Probe "$r\integrated-history-probe.exe" "$r\assets $r\modules\gfx1201 $r\reference $r\flags.txt D:\DLSSNR-Lab\temporal-replay-contract-20261006\encoded-0.f32 D:\DLSSNR-Lab\temporal-replay-contract-20261006\coordinates-0.f32 1280 720 768" 'integrated720'
 }
 # Actual NativeGameFrame bridge/metadata entry gate, still synthetic FFX fixture.
 $config=Get-Content 'D:\DLSSNR-Lab\temporal-replay-contract-20261006\fixture-config.txt'
 $config=$config -replace 'D:\\DLSSNR-Lab\\temporal-replay-contract-20261006\\assets',"$r\assets"
 [IO.File]::WriteAllLines("$r\frame-config.txt",$config+$base+@(('DLSS5_HIP_MODULES='+"$r\modules\gfx1201"),'DLSS5_NETWORK_HEIGHT=720','DLSS5_NETWORK_1080_ROWS=1152','DLSS5_TEMPORAL_MV_UNJITTERED=1','DLSS5_MULTI_PASS=1','DLSS5_MULTI_PASS_SKIN_PROTECT=0','DLSS5_HIP_GRAPH=0','DLSS5_OVERLAP=0','DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_REUSE_HOTKEY=0','DLSS5_HISTORY_GUARD=0','DLSS5_OUTPUT_SMOOTH=0','DLSS5_FAST_TEMPORAL=0','DLSS5_SHOW_FPS=0','DLSS5_NET_TIMING=0'))
 Probe "$r\frame-history-probe.exe" "$r\frame-config.txt" 'frame720'
 # Same legal color fixture converted with the existing codec to1080 geometry.
 $c=Get-Content 'D:\DLSSNR-Lab\temporal-replay-contract-20261006\fixture-config.txt'
 $c=$c -replace 'D:\\DLSSNR-Lab\\temporal-replay-contract-20261006\\assets',"$r\assets"
 $c=$c -replace 'DLSS5_NETWORK_HEIGHT=720','DLSS5_NETWORK_HEIGHT=1080' -replace 'DLSS5_FIT_LARGE=0','DLSS5_FIT_LARGE=1'
 $c=$c -replace 'D:\\DLSSNR-Lab\\temporal-replay-contract-20261006\\encoded-ROUND.f32',"$r\encoded1080.f32" -replace 'D:\\DLSSNR-Lab\\temporal-replay-contract-20261006\\coordinates-ROUND.f32',"$r\coordinates1080.f32" -replace 'D:\\DLSSNR-Lab\\temporal-replay-contract-20261006\\motion-ROUND.f32',"$r\motion1080.f32" -replace 'D:\\DLSSNR-Lab\\temporal-replay-contract-20261006\\receipt-ROUND.txt',"$r\convert1080.txt"
 [IO.File]::WriteAllLines("$r\convert1080-config.txt",$c)
 Probe 'D:\DLSSNR-Lab\temporal-replay-contract-20261006\replay-convert.exe' "$r\convert1080-config.txt" 'convert1080'
 [IO.File]::WriteAllLines("$r\flags1080.txt",$base+@('DLSS5_NETWORK_HEIGHT=1080','DLSS5_NETWORK_1080_ROWS=1152','DLSS5_TEMPORAL_HISTORY_EXPERIMENT=1','DLSS5_TEMPORAL_MV_UNJITTERED=1'))
 Probe "$r\integrated-history-probe.exe" "$r\assets $r\modules\gfx1201 $r\reference $r\flags1080.txt $r\encoded1080.f32 $r\coordinates1080.f32 1920 1080 1152" 'integrated1080'
}finally{$lock.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}

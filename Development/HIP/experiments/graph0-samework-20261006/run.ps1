$ErrorActionPreference='Stop'
$r='D:\DLSSNR-Lab\graph0-samework-20261006';$mods='D:\DLSSNR-Lab\combined-vs041-20261006\modules-current';$f='D:\DLSSNR-Lab\sync-network-gap1080-20261006';$assets='D:\DLSSNR-Lab\history-trial-041a-20261006\assets';$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle {& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game check busy/error'};if(Get-Process|Where-Object {$_.ProcessName -match $games -or $_.ProcessName -match 'rtc_compile|benchmark|pure_fullnn|nr_graph|graph0-capture'}){throw 'game/job live'}}
Idle;if((Get-PSDrive D).Free -lt 100GB){throw 'D free<100GB'}
if((Get-FileHash "$f\fixture\processing1088.rgba32f").Hash -ne '3ef42d34cebd1bc847e5caa3a95b3c3b70f45c9eeed4e828a3e2f85615b49b68'){throw 'input lock'}
if((Get-FileHash "$r\graph0-capture-only.exe").Hash -ne '87fe10fa89ed73741f0aa757351fb0bb0699be472453c93c946ebdfeac539cee'){throw 'caller lock'}
foreach($e in (Get-Content "$r\expected-modules.json" -Raw|ConvertFrom-Json)){if((Get-FileHash "$mods\$($e.name)").Hash -ne $e.sha256){throw "module lock $($e.name)"}}
if((Get-FileHash 'D:\DLSSNR-Lab\fresh-mochi1088-20261006\1088-00-F1\first.rgb32f').Hash -ne '153ac018f5dd5744cff9157661c46c469d01db6018a97c93aec2b1e2e05647f1'){throw 'reference lock'};Copy-Item 'D:\DLSSNR-Lab\fresh-mochi1088-20261006\1088-00-F1\first.rgb32f' "$r\reference.rgb32f";if(Test-Path "$r\first.rgb32f"){throw 'prior run exists no retry'};New-Item -ItemType Directory -Force "$r\cache"|Out-Null
Get-CimInstance Win32_VideoController|Select Name,DriverVersion|ConvertTo-Json|Set-Content "$r\driver.json"
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName="$r\graph0-capture-only.exe";$psi.Arguments="`"$assets`" `"$mods`" `"$f\fast1-1088.flags`" `"$f\fixture\processing1088.rgba32f`" `"$r`" 80 2 1088";$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;$psi.WorkingDirectory=$r
foreach($k in @($psi.EnvironmentVariables.Keys)){if($k.StartsWith('DLSS5_') -or $k.StartsWith('NR_') -or $k.StartsWith('SP_')){$psi.EnvironmentVariables.Remove($k)}}
foreach($k in @('TEMP','TMP','HIP_CACHE_DIR')){$psi.EnvironmentVariables[$k]="$r\cache"}
$p=[Diagnostics.Process]::new();$p.StartInfo=$psi;$p.Start()|Out-Null;$o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -gt $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game began own probe killed'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'own probe watchdog no retry'}}
$p.WaitForExit();$o.Result|Set-Content "$r\capture.stdout.log";$e.Result|Set-Content "$r\capture.stderr.log";if($p.ExitCode){throw "capture prerequisite failed exit=$($p.ExitCode) no retry"};if((Get-FileHash "$r\first.rgb32f").Hash -ne '153ac018f5dd5744cff9157661c46c469d01db6018a97c93aec2b1e2e05647f1'){throw 'eager raw lock'};'CAPTURE_ONLY_PASS_NO_REPLAY_NO_PERFORMANCE'
}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock';'LOCK_RELEASED'}

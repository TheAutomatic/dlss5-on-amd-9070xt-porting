param([Parameter(Mandatory=$true)][string]$InputF32,[Parameter(Mandatory=$true)][string]$Flags,[string]$StockModules='D:\DLSSNR-Lab\history-trial-041a-20261006\modules\gfx1201',[string]$Assets='D:\DLSSNR-Lab\history-trial-041a-20261006\assets')
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\c512-den-gold-20261006';$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle {& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game busy/check failed'};if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'game running'};if(Get-Process|Where-Object {$_.ProcessName -eq 'rtc_compile'}){throw 'compiler active'}}
function RunProbe([string]$Exe,[string]$Arguments,[string]$Name,[bool]$Capture) {
 $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=$Exe;$psi.Arguments=$Arguments;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_') -or $key.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($key)}}
 $psi.EnvironmentVariables['DLSS5_DEN_CAPTURE']=if($Capture){'1'}else{'0'};$psi.EnvironmentVariables['TEMP']="$root\cache";$psi.EnvironmentVariables['TMP']="$root\cache";$psi.EnvironmentVariables['HIP_CACHE_DIR']="$root\cache"
 $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'start failed'};$o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
 while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game began; own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'timeout, no repeat'}}
 $p.WaitForExit();$o.Result|Set-Content "$root\$Name.stdout.log";$e.Result|Set-Content "$root\$Name.stderr.log";if($p.ExitCode){throw "$Name failed $($p.ExitCode); no repeat"}
}
Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
if((Get-FileHash $InputF32).Hash -ne '62f4d12777eb8eb5e049ff34981cfc84cb4a1d65cf5e31415143c94c8aaa325a'){throw 'input SHA changed'}
if(Test-Path "$root\trace-first23\den.u32"){throw 'first23 already measured; no repeat'}
New-Item -ItemType Directory -Force "$root\trace-first23","$root\modules-first23"|Out-Null
foreach($f in Get-ChildItem "$StockModules\*.hsaco"){Copy-Item $f.FullName "$root\modules-first23\$($f.Name)"}
Copy-Item "$root\actual-first23.hsaco" "$root\modules-first23\c512-m32-mh.hsaco" -Force
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try {Idle;RunProbe "$root\actual_probe.exe" "`"$Assets`" `"$root\modules-first23`" `"$Flags`" `"$InputF32`" `"$root\trace-first23`" 1 1 1600 960" 'first23' $true
 if((Get-FileHash "$root\baseline\first.rgb32f").Hash -ne (Get-FileHash "$root\trace-first23\first.rgb32f").Hash){throw 'first23 trace changed fullNN output'}
 'FIRST23_GOLD_PASS same old input/model/output; trace asymmetry/e equality/calls checked by host'
}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock';'LOCK_RELEASED'}

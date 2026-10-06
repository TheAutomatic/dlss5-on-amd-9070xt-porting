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
if(Test-Path "$root\inverse-unit\fixture0.u32"){throw 'existing gold evidence; no repeat'}
New-Item -ItemType Directory -Force "$root\inverse-unit","$root\inverse-old","$root\inverse-new","$root\modules-inverse-old","$root\modules-inverse-new"|Out-Null
foreach($side in 'old','new'){foreach($f in Get-ChildItem "$StockModules\*.hsaco"){Copy-Item $f.FullName "$root\modules-inverse-$side\$($f.Name)"};Copy-Item "$root\$side-comgr.hsaco" "$root\modules-inverse-$side\c512-m32-mh.hsaco" -Force}
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try {Idle;RunProbe "$root\inverse_gold.exe" "`"$root\gold-canonical.hsaco`" `"$root\inverse-unit`"" 'inverse-unit' $false
 foreach($side in 'old','new'){Idle;RunProbe "$root\actual_probe.exe" "`"$Assets`" `"$root\modules-inverse-$side`" `"$Flags`" `"$InputF32`" `"$root\inverse-$side`" 1 1 1600 960" "inverse-$side" $false}
 $a=(Get-FileHash "$root\inverse-old\first.rgb32f").Hash;$b=(Get-FileHash "$root\inverse-new\first.rgb32f").Hash;$stock=(Get-FileHash "$root\baseline\first.rgb32f").Hash;if($a -ne $b -or $a -ne $stock){throw 'canonical old/new/stock wholeNN raw mismatch'}
 'INVERSE_GOLD_PASS eight primitive fixtures/oldnewstock wholeNN samefinite; not performance';$a
}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock';'LOCK_RELEASED'}

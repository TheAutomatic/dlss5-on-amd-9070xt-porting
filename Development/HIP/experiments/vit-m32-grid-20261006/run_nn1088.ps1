param([Parameter(Mandatory=$true)][string]$InputF32,[Parameter(Mandatory=$true)][string]$Flags,[string]$StockModules='D:\DLSSNR-Lab\history-trial-041a-20261006\modules\gfx1201',[string]$Assets='D:\DLSSNR-Lab\history-trial-041a-20261006\assets')
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\vit-m32-grid-20261006';$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle {& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game busy/check failed'};if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'game running'};if(Get-Process|Where-Object {$_.ProcessName -eq 'rtc_compile'}){throw 'compiler active'}}
function RunProbe([string]$Exe,[string]$Arguments,[string]$Name,[bool]$Capture) {
 $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=$Exe;$psi.Arguments=$Arguments;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_') -or $key.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($key)}}
 $psi.EnvironmentVariables['DLSS5_LAB_QB32_GRID']=if($Name -eq 'nn1088-slot-1' -or $Name -eq 'nn1088-slot-2'){'1'}else{'0'};$psi.EnvironmentVariables['DLSS5_DEN_CAPTURE']=if($Capture){'1'}else{'0'};$psi.EnvironmentVariables['TEMP']="$root\cache";$psi.EnvironmentVariables['TMP']="$root\cache";$psi.EnvironmentVariables['HIP_CACHE_DIR']="$root\cache"
 $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'start failed'};$o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
 while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game began; own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();$p.WaitForExit();$o.Result|Set-Content "$root\$Name.timeout.stdout.log";$e.Result|Set-Content "$root\$Name.timeout.stderr.log";throw 'timeout, no repeat'}}
 $p.WaitForExit();$o.Result|Set-Content "$root\$Name.stdout.log";$e.Result|Set-Content "$root\$Name.stderr.log";if($p.ExitCode){throw "$Name failed $($p.ExitCode); no repeat"}
}
New-Item -ItemType Directory -Force "$root\cache"|Out-Null;Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
if((Get-FileHash $InputF32).Hash -ne '3ef42d34cebd1bc847e5caa3a95b3c3b70f45c9eeed4e828a3e2f85615b49b68'){throw '1088 locked input SHA changed'}
foreach($side in 'old','new'){if((Get-FileHash "$root\new-comgr.hsaco").Hash -ne (Get-FileHash "$root\modules-$side\deep_fast-packed-fast.hsaco").Hash){throw 'module stage changed'}}
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try {for($slot=0;$slot -lt 4;$slot++){Idle;$side=if($slot -eq 1 -or $slot -eq 2){'new'}else{'old'};$dir="$root\nn1088-slot-$slot";if(Test-Path $dir){throw 'existing firstscreen slot, no repeat'};New-Item -ItemType Directory $dir|Out-Null
 RunProbe "$root\benchmark1088.exe" "`"$Assets`" `"$root\modules-$side`" `"$Flags`" `"$InputF32`" `"$dir`" 80 160 1088" "nn1088-slot-$slot" $false
 }
 $hashes=@(foreach($slot in 0..3){foreach($edge in 'first','last'){Get-FileHash "$root\nn1088-slot-$slot\$edge.rgb32f"|Select-Object Path,Hash}});foreach($slot in 0..3){if($hashes[$slot*2].Hash -ne $hashes[$slot*2+1].Hash){throw 'variant edge repeat mismatch'}};if($hashes[0].Hash -ne $hashes[6].Hash -or $hashes[2].Hash -ne $hashes[4].Hash){throw 'samevariant slot mismatch'};$hashes|ConvertTo-Json|Set-Content "$root\nn1088-raw-hashes.json";'NN1088_ABBA_PASS rawsame; stats must be audited CPU; no repeat'
}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock';'LOCK_RELEASED'}

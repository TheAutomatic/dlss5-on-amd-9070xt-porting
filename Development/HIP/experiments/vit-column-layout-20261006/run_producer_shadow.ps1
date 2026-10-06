$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\vit-column-layout-20261006';$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle {& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game busy/check failed'};if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'game running'};if(Get-Process|Where-Object {$_.ProcessName -eq 'rtc_compile'}){throw 'compiler active'}}
function RunProbe([string]$Exe,[string]$Arguments,[string]$Name,[bool]$Capture) {
 $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=$Exe;$psi.Arguments=$Arguments;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_') -or $key.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($key)}}
 $psi.EnvironmentVariables['DLSS5_LAB_COLUMN_PRODUCER_OLD']="$root\producer\old-comgr.hsaco";$psi.EnvironmentVariables['DLSS5_LAB_COLUMN_PRODUCER_NEW']="$root\producer\new-comgr.hsaco";$psi.EnvironmentVariables['DLSS5_DEN_CAPTURE']=if($Capture){'1'}else{'0'};$psi.EnvironmentVariables['TEMP']="$root\cache";$psi.EnvironmentVariables['TMP']="$root\cache";$psi.EnvironmentVariables['HIP_CACHE_DIR']="$root\cache"
 $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'start failed'};$o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
 while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game began; own probe stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'timeout, no repeat'}}
 $p.WaitForExit();$o.Result|Set-Content "$root\$Name.stdout.log";$e.Result|Set-Content "$root\$Name.stderr.log";if($p.ExitCode){throw "$Name failed $($p.ExitCode); no repeat"}
}

New-Item -ItemType Directory -Force "$root\cache"|Out-Null;Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'Dfree<100GB'}
$dir="$root\producer-shadow";if(Test-Path "$dir\input.bin"){throw 'existing producer capture no repeat'};New-Item -ItemType Directory -Force $dir|Out-Null
foreach($entry in @(@('old','a085694b8679aee18b169a5aa2d886b12d579809b9f2bbfd4e097d4cf692b986'),@('new','876fca9c5d7cb7bd124c8bcd7df6b7e5b5be79bb8a1e3764af89cd4e452789ff'))){if((Get-FileHash "$root\producer\$($entry[0])-comgr.hsaco").Hash -ne $entry[1]){throw 'producer identity'}}
$base='D:\DLSSNR-Lab\history-trial-041a-20261006';$inputFile='D:\DLSSNR-Lab\sync-network-gap1080-20261006\fixture\processing1088.rgba32f';$flags='D:\DLSSNR-Lab\sync-network-gap1080-20261006\fast1-1088.flags'
if((Get-FileHash $inputFile).Hash -ne '3ef42d34cebd1bc847e5caa3a95b3c3b70f45c9eeed4e828a3e2f85615b49b68'){throw 'inputidentity'}
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{Idle;RunProbe "$root\shadow.exe" "`"$base\assets`" `"$root\modules-old`" `"$flags`" `"$inputFile`" `"$dir`" 1 1 1088" 'producer-shadow' $false;if((Get-FileHash "$dir\first.rgb32f").Hash -ne '153ac018f5dd5744cff9157661c46c469d01db6018a97c93aec2b1e2e05647f1'){throw 'shadow changedoriginalchain'};'PRODUCER_SHADOW_CAPTURE_PASS CPUinverse_pending_NO_PERFORMANCE'}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock';'LOCK_RELEASED'}

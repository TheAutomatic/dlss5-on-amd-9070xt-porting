$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$r='D:\DLSSNR-Lab\body22-down-local-20261006';$out="$r\gold-1";$mods='D:\DLSSNR-Lab\combined-vs041-20261006\modules-current';$fixture='D:\DLSSNR-Lab\sync-network-gap1080-20261006';$assets='D:\DLSSNR-Lab\history-trial-041a-20261006\assets';$lock='D:\DLSSNR-Lab\gpu.lock';$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64'
function CheckGame {if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'Game running'}}
CheckGame
if(Get-Process|Where-Object {$_.ProcessName -match 'benchmark|rtc_compile|nr_graph|pure_fullnn|gold|frame-probe'}){throw 'Existing experiment/compile'}
if((Get-PSDrive D).Free -lt 100GB){throw 'Free D<100GB'}
$expected=@{'gold.exe'='39483549585e5d4dc9cb2883fb9138ce51923303644fa9e30885f72ca35be28a';'candidate.hsaco'='8a40164c6f68b4d9f3e270f8a3f5d589897bc487e22ead827615d6be890f2dc6'}
foreach($n in $expected.Keys){if((Get-FileHash "$r\$n").Hash.ToLower() -ne $expected[$n]){throw "payload drift $n"}}
if((Get-FileHash "$mods\c64-wave2-fast.hsaco").Hash.ToLower() -ne '65848e8d21ef4e647ff9c1f995415676ca47d669610354b7c6743e745525c799'){throw 'Body stock drift'}
if((Get-FileHash "$mods\multihead-fast-padded-wave-packed.hsaco").Hash.ToLower() -ne 'e452eedb7e07084431ed20e31a0187eedb5ed6630fa5f3ec03209d26e8ad6130'){throw 'Down stock drift'}
if((Get-FileHash "$fixture\fixture\processing1088.rgba32f").Hash.ToLower() -ne '3ef42d34cebd1bc847e5caa3a95b3c3b70f45c9eeed4e828a3e2f85615b49b68'){throw 'Input drift'}
if(Test-Path $out){throw 'No overwrite'};New-Item -ItemType Directory $out|Out-Null
$owner=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);$p=$null
try{
 CheckGame;$psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName="$r\gold.exe";$psi.Arguments="$assets $mods $fixture\fast1-1088.flags $fixture\fixture\processing1088.rgba32f $r\candidate.hsaco $out";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 foreach($k in @($psi.EnvironmentVariables.Keys)){if($k.StartsWith('DLSS5_') -or $k.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($k)}}
 $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'start'};$std=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
 while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'Game began stopped own gold'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'Own gold timeout'}}
 $p.WaitForExit();$std.Result|Set-Content "$out\stdout.log";$err.Result|Set-Content "$out\stderr.log";Get-Content "$out\stdout.log";if($p.ExitCode -ne 0){throw "Gold failed exit$($p.ExitCode)"}
 Get-ChildItem $out -File|ForEach-Object {@{name=$_.Name;bytes=$_.Length;SHA=(Get-FileHash $_.FullName).Hash}}|ConvertTo-Json|Set-Content "$out\manifest.json"
}finally{if($p -and !$p.HasExited){$p.Kill()};$owner.Dispose();Remove-Item $lock -Force;'LOCK_RELEASED'}

$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$r='D:\DLSSNR-Lab\up48-body48-local-20261006';$out="$r\gold-1";$mods='D:\DLSSNR-Lab\combined-vs041-20261006\modules-current';$fixture='D:\DLSSNR-Lab\sync-network-gap1080-20261006';$assets='D:\DLSSNR-Lab\history-trial-041a-20261006\assets';$lock='D:\DLSSNR-Lab\gpu.lock';$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64'
function CheckGame {if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'Game running'}}
CheckGame
if(Get-Process|Where-Object {$_.ProcessName -match 'benchmark|rtc_compile|nr_graph|pure_fullnn|gold|frame-probe'}){throw 'Existing experiment/compile'}
if((Get-PSDrive D).Free -lt 100GB){throw 'Free D<100GB'}
$expected=@{'gold.exe'='ec8a9cc8ee71408cde33023bd680350171329bf534c14a63fdfc925b83714b5c';'candidate.hsaco'='37d039f776a32534f3d516895ca0f04b1923d7cf5204224aba56f8a04607b834'}
foreach($n in $expected.Keys){if((Get-FileHash "$r\$n").Hash.ToLower() -ne $expected[$n]){throw "payload drift $n"}}
if((Get-FileHash "$mods\c64-wave2-fast.hsaco").Hash.ToLower() -ne '65848e8d21ef4e647ff9c1f995415676ca47d669610354b7c6743e745525c799'){throw 'Body stock drift'}
if((Get-FileHash "$mods\deep_fast-packed-fast.hsaco").Hash.ToLower() -ne '11a25ae3fea75f83763ab6d5729c4f426dabda11299d1be6092d142b810e27b8'){throw 'Up stock drift'}
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

param([switch]$Screen)
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$r='D:\DLSSNR-Lab\up48-body48-local-20261006';$out=if($Screen){"$r\screen-1"}else{"$r\whole-gold-guardfix"};$mods='D:\DLSSNR-Lab\combined-vs041-20261006\modules-current';$fixture='D:\DLSSNR-Lab\sync-network-gap1080-20261006';$assets='D:\DLSSNR-Lab\history-trial-041a-20261006\assets';$lock='D:\DLSSNR-Lab\gpu.lock';$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64'
function CheckGame {if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'Game running'}}
CheckGame
if(Get-Process|Where-Object {$_.ProcessName -match 'benchmark|rtc_compile|nr_graph|pure_fullnn|gold|frame-probe'}){throw 'Existing experiment/compile'}
if((Get-PSDrive D).Free -lt 100GB){throw 'Free D<100GB'}
$expected=@{'benchmark.exe'='5f586f81d6db9c44d00c4fb01c3f95d64decf2d333a6e8954454f2899902be6f';'candidate.hsaco'='37d039f776a32534f3d516895ca0f04b1923d7cf5204224aba56f8a04607b834'}
foreach($n in $expected.Keys){if((Get-FileHash "$r\$n").Hash.ToLower() -ne $expected[$n]){throw "payload drift $n"}}
if((Get-FileHash "$mods\c64-wave2-fast.hsaco").Hash.ToLower() -ne '65848e8d21ef4e647ff9c1f995415676ca47d669610354b7c6743e745525c799'){throw 'Body stock drift'}
if((Get-FileHash "$mods\multihead-fast-padded-wave-packed.hsaco").Hash.ToLower() -ne 'e452eedb7e07084431ed20e31a0187eedb5ed6630fa5f3ec03209d26e8ad6130'){throw 'Down stock drift'}
if((Get-FileHash "$fixture\fixture\processing1088.rgba32f").Hash.ToLower() -ne '3ef42d34cebd1bc847e5caa3a95b3c3b70f45c9eeed4e828a3e2f85615b49b68'){throw 'Input drift'}
if(Test-Path $out){throw 'No overwrite'};New-Item -ItemType Directory $out|Out-Null

$owner=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);$p=$null
try{
 $schedule=if($Screen){@('A','N','N','A')}else{@('A','N')};$warm=if($Screen){80}else{0};$n=if($Screen){160}else{1};$i=0;$hashes=@()
 foreach($kind in $schedule){
  CheckGame;$d="$out\slot-$i-$kind";New-Item -ItemType Directory $d|Out-Null
  $cm=if($kind -eq 'N'){"$r\candidate.hsaco"}else{'-'}
  $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName="$r\benchmark.exe";$psi.Arguments="$assets $mods $fixture\fast1-1088.flags $fixture\fixture\processing1088.rgba32f $d $warm $n 1088 $cm";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
  foreach($k in @($psi.EnvironmentVariables.Keys)){if($k.StartsWith('DLSS5_') -or $k.StartsWith('NR_')){$psi.EnvironmentVariables.Remove($k)}}
  if(!$Screen){$psi.EnvironmentVariables["DLSS5_FUSION_SEQUENCE"]="1"}
  if($Screen -and $psi.EnvironmentVariables.ContainsKey("DLSS5_FUSION_SEQUENCE")){throw "Fn sequence env must be absent"}
  @{fn_sequence_env_present=$psi.EnvironmentVariables.ContainsKey("DLSS5_FUSION_SEQUENCE");screen=[bool]$Screen}|ConvertTo-Json|Set-Content "$d\host-env.json"
  $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;if(!$p.Start()){throw 'start'};$std=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
  while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'game began stopped own'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 60){$p.Kill();throw 'Own timeout'}}
  $p.WaitForExit();$std.Result|Set-Content "$d\stdout.log";$err.Result|Set-Content "$d\stderr.log";Get-Content "$d\stdout.log";if($p.ExitCode -ne 0){throw "exit$($p.ExitCode)"}
  $count=if($kind -eq 'N'){160}else{161};$fused=if($kind -eq 'N'){1+$warm+$n}else{0}
  if($std.Result -notmatch "FUSION_ROUTE dispatch_per_frame=$count fused_calls=$fused "){throw 'Actual route count failed'}
  foreach($name in @('first.rgb32f','last.rgb32f')){$hashes+=((Get-FileHash "$d\$name").Hash)}
  $i++
 }
 if(@($hashes|Select-Object -Unique).Count -ne 1){throw 'Whole raw hash changed'}
 $hashes|ConvertTo-Json|Set-Content "$out\whole-hashes.json";'WHOLE_RAW_ROUTE_PASS'
}finally{if($p -and !$p.HasExited){$p.Kill()};$owner.Dispose();Remove-Item $lock -Force;'LOCK_RELEASED'}

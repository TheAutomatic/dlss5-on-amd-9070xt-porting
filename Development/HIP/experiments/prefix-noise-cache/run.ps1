param([string]$Root='D:\DLSSNR-Lab\prefix-noise-cache-20261006',[uint32]$Width=1920,[uint32]$Height=1088,[string]$InputPath='D:\DLSSNR-Lab\sync-network-gap1080-20261006\fixture\processing1088.rgba32f')
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$base='D:\DLSSNR-Lab\history-trial-041a-20261006';$fixturePath=$InputPath;$lock='D:\DLSSNR-Lab\gpu.lock'
$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64'
function CheckGame {if(Get-Process|Where-Object {$_.ProcessName -match $games}){throw 'Game running; leave it alone'}}
CheckGame
if(Get-Process|Where-Object {$_.ProcessName -match 'benchmark|nr_graph|rtc_compile|frame-probe|integrated-probe|prefix-cache-probe'}){throw 'Another probe/compile process present'}
if((Get-PSDrive D).Free -lt 100GB){throw 'D write/cache free space below100GiB'}
$owner=New-Object IO.FileStream($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
$p=$null
try{
 $labelBytes=[Text.Encoding]::UTF8.GetBytes('prefix-noise-cache '+$PID);$owner.Write($labelBytes,0,$labelBytes.Length);$owner.Flush()
 $modules="$Root\modules";if(!(Test-Path $modules)){
 New-Item -ItemType Directory $modules|Out-Null
 Copy-Item "$base\modules\gfx1201\*" $modules
 Copy-Item "$Root\gfx1201\c32-wave1.hsaco","$Root\gfx1201\c32-wave1-fast.hsaco" $modules -Force
 }else{foreach($name in 'c32-wave1.hsaco','c32-wave1-fast.hsaco'){if((Get-FileHash "$Root\gfx1201\$name").Hash -ne (Get-FileHash "$modules\$name").Hash){throw 'Existing candidate module mismatch'}}}
 New-Item -ItemType Directory "$Root\cache" -Force|Out-Null
 function RunProbe($label,$fast,$mode,$mod){
  CheckGame;$out="$Root\$label";if(Test-Path $out){if($mode -ne 'gold' -or (Test-Path "$out\timing.csv")){throw 'Existing slot: no replay or overwriting performance evidence'}};New-Item -ItemType Directory $out -Force|Out-Null
  $psi=New-Object Diagnostics.ProcessStartInfo;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;$psi.WorkingDirectory=$Root
  foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_')){$psi.EnvironmentVariables.Remove($key)}}
  $psi.EnvironmentVariables['TEMP']="$Root\cache";$psi.EnvironmentVariables['TMP']="$Root\cache";$psi.EnvironmentVariables['HIP_CACHE_DIR']="$Root\cache"
  $flagsPath=if($Height -eq 960){"D:\DLSSNR-Lab\sync-network-gap-20261006\fast$fast.flags"}else{"D:\DLSSNR-Lab\sync-network-gap1080-20261006\fast$fast-$Height.flags"}
  $psi.FileName="$Root\probe.exe";$psi.Arguments="$base\assets $mod $flagsPath $fixturePath $out $Width $Height $mode 160"
  $script:p=New-Object Diagnostics.Process;$p.StartInfo=$psi;if(!$p.Start()){throw 'Start failed'};$stdout=$p.StandardOutput.ReadToEndAsync();$stderr=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
  while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|Where-Object {$_.ProcessName -match $games}){$p.Kill();throw 'Game started: stopped only own probe'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 90){$p.Kill();throw 'Own probe timeout'}}
  $p.WaitForExit();$stdout.Result|Set-Content "$out\stdout.log";$stderr.Result|Set-Content "$out\stderr.log";if($p.ExitCode){throw "Probe failed $label exit=$($p.ExitCode)"}
  Get-Content "$out\stdout.log"|Select-String 'GOLD|PREFIX_NOISE_CACHE|PREFIX_CACHE_NETWORK'
 }
 # Primitive half-domain, full current prefix main/down, temporal input and key-transition correctness before time.
 RunProbe 'gold-F0' 0 'gold' $modules;RunProbe 'gold-F1' 1 'gold' $modules
 # One current FAST1 screen only. Stock A validates patched-old-kernel equivalence; then A-cache-cache-A.
 RunProbe 'stock-F1' 1 '0' "$base\modules\gfx1201"
 foreach($slot in @(@('A0','0'),@('B0','1'),@('B1','1'),@('A1','0'))){RunProbe $slot[0] 1 $slot[1] $modules}
 $reference=(Get-FileHash "$Root\stock-F1\last.rgb32f").Hash
 foreach($slot in 'stock-F1','A0','B0','B1','A1'){
  foreach($edge in 'first','last'){if((Get-FileHash "$Root\$slot\$edge.rgb32f").Hash -ne $reference){throw "Current complete network raw SHA differs $slot/$edge"}}
 }
 'PREFIX_CACHE_FIRST_SCREEN_DONE: no extra rounds; judge paired mean/p99 before any formal expansion'
}finally{if($p -and !$p.HasExited){$p.Kill()};$owner.Dispose();[IO.File]::Delete($lock);'LOCK_RELEASED'}

param([string]$RestoreBackup='')
$ErrorActionPreference='Stop'
if(Get-Process | Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark$|^rt_bench$'}){throw 'GPU/game busy'}
$root=Split-Path -Parent $MyInvocation.MyCommand.Path
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
$hip="$game\DLSS5-AMD\native-game-tiled-assets\HIP";$sums="$hip\SHA256SUMS"
$m=Get-Content "$root\payload.json" -Raw|ConvertFrom-Json
function Restore($b){
 foreach($f in $m.files){$rel="$($f.arch)\$($f.module)";Copy-Item "$b\$rel" "$hip\$rel" -Force;if((Get-FileHash "$b\$rel").Hash -ne (Get-FileHash "$hip\$rel").Hash){throw 'restore mismatch'}}
 if(Test-Path "$b\SHA256SUMS"){Copy-Item "$b\SHA256SUMS" $sums -Force}
}
if($RestoreBackup){Restore $RestoreBackup;"RESTORED $RestoreBackup";exit}
$protected=@("$game\dlss5-amd.addon64","$game\dxgi.dll","$game\OptiScaler.ini","$game\DLSS5-AMD\native-game-flags.txt")
$before=@{};foreach($f in $protected){$before[$f]=(Get-FileHash $f).Hash}
$allBefore=@{};foreach($f in Get-ChildItem $hip -Recurse -Filter '*.hsaco'){$allBefore[$f.FullName]=(Get-FileHash $f.FullName).Hash}
if($allBefore.Count -ne 60){throw 'Expected 60 installed modules'}
foreach($f in $m.files){
 $rel="$($f.arch)\$($f.module)"
 if((Get-FileHash "$hip\$rel").Hash -ne $f.baseline){throw "Unexpected baseline: $rel"}
 if((Get-FileHash "$root\payload\$rel").Hash -ne $f.candidate){throw "Bad payload: $rel"}
}
$b="$root\backups\stellar-$(Get-Date -Format yyyyMMdd-HHmmss)"
foreach($f in $m.files){$rel="$($f.arch)\$($f.module)";New-Item -ItemType Directory -Force "$b\$($f.arch)"|Out-Null;Copy-Item "$hip\$rel" "$b\$rel"}
if(Test-Path $sums){Copy-Item $sums "$b\SHA256SUMS"}
try{
 foreach($f in $m.files){$rel="$($f.arch)\$($f.module)";Copy-Item "$root\payload\$rel" "$hip\$rel" -Force;if((Get-FileHash "$hip\$rel").Hash -ne $f.candidate){throw "Readback mismatch: $rel"}}
 if(Test-Path $sums){
  $lines=@(Get-Content $sums)
  foreach($f in $m.files){$rel="$($f.arch)/$($f.module)";$pattern='\s+'+[regex]::Escape($rel)+'$';$found=$false
   $lines=@(foreach($line in $lines){if($line -match $pattern){$found=$true;"$($f.candidate.ToLower())  $rel"}else{$line}})
   if(!$found){throw "Missing checksum entry: $rel"}
  }
  [IO.File]::WriteAllLines($sums,$lines,(New-Object Text.UTF8Encoding($false)))
 }
 foreach($f in $protected){if((Get-FileHash $f).Hash -ne $before[$f]){throw "Protected file changed: $f"}}
 $expected=@($m.files|ForEach-Object{"$hip\$($_.arch)\$($_.module)"});$changed=@()
 foreach($f in $allBefore.Keys){if((Get-FileHash $f).Hash -ne $allBefore[$f]){if($f -notin $expected){throw "Unexpected changed module: $f"};$changed+=$f}}
 if($changed.Count -ne 4){throw 'Expected exactly four changed module files'}
}catch{Restore $b;throw}
[pscustomobject]@{backup=$b;files=$m.files;modules_changed=$changed;protected_hashes=$before;other_modules_unchanged=56;addon_changed=$false;flags_changed=$false}|ConvertTo-Json -Depth 6|Set-Content "$root\installed.json"
"INSTALLED c32-wave1 + c64-wave2 x2; BACKUP=$b"

param([string]$RestoreBackup='')
$ErrorActionPreference='Stop'
if(Get-Process SB-Win64-Shipping,LOP-Win64-Shipping,OnimushaWotS,re9,benchmark -ErrorAction SilentlyContinue){throw 'GPU/game busy'}
$root=Split-Path -Parent $MyInvocation.MyCommand.Path
$hip='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets\HIP'
$arches=@('gfx1200','gfx1201');$sums="$hip\SHA256SUMS"
function Restore($b){
 foreach($a in $arches){Copy-Item "$b\$a\c64-wave2.hsaco" "$hip\$a\c64-wave2.hsaco" -Force;if((Get-FileHash "$b\$a\c64-wave2.hsaco").Hash -ne (Get-FileHash "$hip\$a\c64-wave2.hsaco").Hash){throw 'restore mismatch'}}
 if(Test-Path "$b\SHA256SUMS"){Copy-Item "$b\SHA256SUMS" $sums -Force}
}
if($RestoreBackup){Restore $RestoreBackup;"RESTORED $RestoreBackup";exit}
$game=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $hip))
$protected=@("$game\dlss5-amd.addon64","$game\dxgi.dll","$game\OptiScaler.ini","$game\DLSS5-AMD\native-game-flags.txt")
$before=@{};foreach($f in $protected){$before[$f]=(Get-FileHash $f).Hash}
$m=Get-Content "$root\payload.json" -Raw|ConvertFrom-Json
foreach($a in $arches){
 if((Get-FileHash "$hip\$a\c64-wave2.hsaco").Hash -ne $m.baseline.$a){throw "Unexpected installed baseline: $a"}
 if((Get-FileHash "$root\payload\$a\c64-wave2.hsaco").Hash -ne $m.candidate.$a){throw "Invalid payload: $a"}
}
$b="$root\backups\stellar-$(Get-Date -Format yyyyMMdd-HHmmss)"
foreach($a in $arches){New-Item -ItemType Directory -Force "$b\$a"|Out-Null;Copy-Item "$hip\$a\c64-wave2.hsaco" "$b\$a\c64-wave2.hsaco"}
if(Test-Path $sums){Copy-Item $sums "$b\SHA256SUMS"}
try{
 foreach($a in $arches){Copy-Item "$root\payload\$a\c64-wave2.hsaco" "$hip\$a\c64-wave2.hsaco" -Force;if((Get-FileHash "$hip\$a\c64-wave2.hsaco").Hash -ne $m.candidate.$a){throw "copy mismatch: $a"}}
 if(Test-Path $sums){
  $lines=@(Get-Content $sums)
  foreach($a in $arches){$found=$false;$lines=@(foreach($line in $lines){if($line -match "\s+$a/c64-wave2\.hsaco$"){$found=$true;"$($m.candidate.$a.ToLower())  $a/c64-wave2.hsaco"}else{$line}});if(!$found){throw "missing checksum entry: $a"}}
  [IO.File]::WriteAllLines($sums,$lines,(New-Object Text.UTF8Encoding($false)))
 }
 foreach($f in $protected){if((Get-FileHash $f).Hash -ne $before[$f]){throw "Protected file changed: $f"}}
}catch{Restore $b;throw}
[pscustomobject]@{backup=$b;candidate=$m.candidate;modules_changed=2;protected_hashes=$before;addon_changed=$false;flags_changed=$false}|ConvertTo-Json|Set-Content "$root\installed.json"
"INSTALLED c64-wave2 x2; BACKUP=$b"

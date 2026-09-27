param([string]$RestoreBackup='')
$ErrorActionPreference='Stop'
if(Get-Process SB-Win64-Shipping,LOP-Win64-Shipping,OnimushaWotS,re9,benchmark,rt_bench -ErrorAction SilentlyContinue){throw 'GPU/game busy'}
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
$root=Split-Path -Parent $MyInvocation.MyCommand.Path
function Restore($b){
 $m=Get-Content "$b\before.json" -Raw|ConvertFrom-Json
 foreach($f in $m.files){
  $dest=Join-Path $g $f.path
  if($f.existed){Copy-Item (Join-Path $b $f.path) $dest -Force;if((Get-FileHash $dest).Hash -ne $f.sha256){throw "restore mismatch $dest"}}
  elseif(Test-Path $dest){Remove-Item $dest}
 }
}
if($RestoreBackup){Restore $RestoreBackup;"RESTORED $RestoreBackup";exit}
$m=Get-Content "$root\payload.json" -Raw|ConvertFrom-Json
foreach($f in $m.files){
 $dest=Join-Path $g $f.path
 if($f.baseline){if(!(Test-Path $dest) -or (Get-FileHash $dest).Hash -ne $f.baseline){throw "Unexpected baseline $dest"}}
 elseif(Test-Path $dest){throw "Unexpected existing new file $dest"}
 if((Get-FileHash (Join-Path "$root\payload" $f.path)).Hash -ne $f.candidate){throw "Invalid payload $($f.path)"}
}
$protected=@{};foreach($f in $m.protected){$dest=Join-Path $g $f.path;if((Get-FileHash $dest).Hash -ne $f.sha256){throw "Protected baseline changed $dest"};$protected[$dest]=$f.sha256}
$b="$root\backups\stellar-$(Get-Date -Format yyyyMMdd-HHmmss)";New-Item -ItemType Directory -Force $b|Out-Null
$before=@(foreach($f in $m.files){
 $dest=Join-Path $g $f.path;$exists=Test-Path $dest;$sha=$null
 if($exists){$save=Join-Path $b $f.path;New-Item -ItemType Directory -Force (Split-Path $save)|Out-Null;Copy-Item $dest $save;$sha=(Get-FileHash $save).Hash}
 [pscustomobject]@{path=$f.path;existed=$exists;sha256=$sha}
})
@{files=$before}|ConvertTo-Json -Depth 5|Set-Content "$b\before.json"
try{
 foreach($f in $m.files){$dest=Join-Path $g $f.path;New-Item -ItemType Directory -Force (Split-Path $dest)|Out-Null;Copy-Item (Join-Path "$root\payload" $f.path) $dest -Force;if((Get-FileHash $dest).Hash -ne $f.candidate){throw "copy mismatch $dest"}}
 foreach($dest in $protected.Keys){if((Get-FileHash $dest).Hash -ne $protected[$dest]){throw "Protected file changed $dest"}}
}catch{Restore $b;throw}
@{backup=$b;files=$m.files;protected=$protected}|ConvertTo-Json -Depth 5|Set-Content "$root\installed.json"
"INSTALLED vit stream; BACKUP=$b"

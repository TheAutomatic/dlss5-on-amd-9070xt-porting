param([string]$RestoreBackup='')
$ErrorActionPreference='Stop'
$r='D:\DLSSNR-Lab\hip-backend\c512-fusion'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
function Idle {if(Get-Process|Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile'}){throw 'GPU/game busy'}}
function Hash($p){(Get-FileHash $p).Hash}
function Restore($b){
 $manifest=Import-Csv "$b\manifest.csv"
 foreach($f in $manifest){if((Hash "$b\$($f.file)") -ne $f.sha){throw 'Backup checksum mismatch'}}
 Idle
 foreach($f in $manifest){Copy-Item "$b\$($f.file)" "$g\$($f.file)" -Force;if((Hash "$g\$($f.file)") -ne $f.sha){throw 'Restore checksum mismatch'}}
}
Idle
if($RestoreBackup){Restore $RestoreBackup;"RESTORED $RestoreBackup";exit}
$m=Get-Content "$r\payload.json" -Raw|ConvertFrom-Json
$before=Get-Content "$r\before.json" -Raw|ConvertFrom-Json
foreach($p in $before.PSObject.Properties){if((Hash $p.Name) -ne $p.Value){throw "Installed baseline changed: $($p.Name)"}}
$flags="$g\DLSS5-AMD\native-game-flags.txt"
if('DLSS5_DIRECT_IO=3' -notin [IO.File]::ReadAllLines($flags)){throw 'Expected DIRECT_IO=3'}
if('DLSS5_MAKE_RESIDENT_EVERY=60' -notin [IO.File]::ReadAllLines($flags)){throw 'Resident setting changed; preserve current flags'}
foreach($f in $m.files){if((Hash "$r\$($f.source)") -ne $f.sha){throw "Payload mismatch $($f.source)"}}
$protected=@($flags,"$g\dxgi.dll","$g\OptiScaler.ini","$g\DLSS5-AMD\native-game-tiled-assets\native_game_rgb_input.hlsl")
$protectedBefore=@{};foreach($p in $protected){$protectedBefore[$p]=Hash $p}
$sumsRel='DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS'
$rels=@($m.files|ForEach-Object{$_.target})+@($sumsRel)
$b="$r\backups\stellar-$(Get-Date -Format yyyyMMdd-HHmmss)"
foreach($rel in $rels){New-Item -ItemType Directory -Force (Split-Path "$b\$rel")|Out-Null;Copy-Item "$g\$rel" "$b\$rel";if((Hash "$b\$rel") -ne (Hash "$g\$rel")){throw 'Backup readback mismatch'}}
@($rels|ForEach-Object{[pscustomobject]@{file=$_;sha=(Hash "$b\$_")}})|Export-Csv "$b\manifest.csv" -NoTypeInformation
Idle
try{
 foreach($f in $m.files){Copy-Item "$r\$($f.source)" "$g\$($f.target)" -Force;if((Hash "$g\$($f.target)") -ne $f.sha){throw 'Install readback mismatch'}}
 $lines=[IO.File]::ReadAllLines("$g\$sumsRel")
 foreach($f in $m.files|Where-Object{$_.target -like '*.hsaco'}){
  $rel=($f.target -split 'HIP\\')[1].Replace('\','/');$found=0
  $lines=@(foreach($line in $lines){if($line -match ('\s+'+[regex]::Escape($rel)+'$')){$found++;"$($f.sha.ToLower())  $rel"}else{$line}})
  if($found -ne 1){throw "Checksum entry $rel"}
 }
 [IO.File]::WriteAllLines("$g\$sumsRel",$lines,(New-Object Text.UTF8Encoding($false)))
 foreach($p in $protected){if((Hash $p) -ne $protectedBefore[$p]){throw "Protected file changed $p"}}
 $changed=@($m.files|ForEach-Object{"$g\$($_.target)"})
 foreach($p in $before.PSObject.Properties){if($p.Name -notin $changed -and (Hash $p.Name) -ne $p.Value){throw "Unexpected change $($p.Name)"}}
}catch{Restore $b;throw}
[pscustomobject]@{backup=$b;files=$m.files;direct_io=3;make_resident_every=60;protected=$protectedBefore;other_modules_unchanged=(60-@($m.files|Where-Object{$_.target -like '*.hsaco'}).Count);release_published=$false}|ConvertTo-Json -Depth 5|Set-Content "$r\installed.json"
"INSTALLED backup=$b addon=$((Hash "$g\dlss5-amd.addon64")) DIRECT_IO=3"

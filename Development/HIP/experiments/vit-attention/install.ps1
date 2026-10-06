param([string]$RestoreBackup='')
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\vit-attention-20260929'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
function Idle {if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^rtc_compile|^Magpie|^runtime-smoke'}){throw 'GPU/game busy'}}
function Restore($backup){foreach($f in (Get-Content "$backup\backup.json" -Raw|ConvertFrom-Json)){$dst=Join-Path $game $f.relative;Copy-Item (Join-Path $backup $f.relative) $dst -Force;if((Get-FileHash $dst).Hash -ne $f.sha256){throw 'Restore mismatch'}}}
Idle
if($RestoreBackup){Restore $RestoreBackup;'RESTORED';exit 0}
$snapshot=Get-Content "$root\snapshot.json" -Raw|ConvertFrom-Json
foreach($f in $snapshot){if((Get-FileHash $f.path).Hash -ne $f.sha256){throw "Installed baseline changed: $($f.path)"}}
$flags=Get-Content "$game\DLSS5-AMD\native-game-flags.txt" -Raw
foreach($p in @(@('DLSS5_DIRECT_IO','3'),@('DLSS5_MAKE_RESIDENT_EVERY','60'),@('DLSS5_HIP_SWIN_RUN','1'))){if([regex]::Match($flags,"(?m)^\s*$($p[0])\s*=\s*(\d+)").Groups[1].Value -ne $p[1]){throw 'Required flag changed'}}
$payload=Get-Content "$root\payload\manifest.json" -Raw|ConvertFrom-Json
foreach($f in $payload.files){if((Get-FileHash (Join-Path "$root\payload" $f.source)).Hash.ToLower() -ne $f.sha256){throw 'Payload hash mismatch'}}
$sum='DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS'
$backup="$root\backups\stellar-$(Get-Date -Format yyyyMMdd-HHmmss)";New-Item -ItemType Directory -Force $backup|Out-Null
$save=@();foreach($rel in @($payload.files|ForEach-Object{$_.relative})+@($sum)){$src=Join-Path $game $rel;$dst=Join-Path $backup $rel;New-Item -ItemType Directory -Force (Split-Path -Parent $dst)|Out-Null;Copy-Item $src $dst;$sha=(Get-FileHash $src).Hash;if((Get-FileHash $dst).Hash -ne $sha){throw 'Backup mismatch'};$save+=@{relative=$rel;sha256=$sha}}
$save|ConvertTo-Json -Depth 4|Set-Content "$backup\backup.json"
Copy-Item "$root\snapshot.json" "$backup\snapshot.json"
try{
 Idle
 foreach($f in $payload.files){Copy-Item (Join-Path "$root\payload" $f.source) (Join-Path $game $f.relative) -Force}
 $hip=Join-Path $game 'DLSS5-AMD\native-game-tiled-assets\HIP';$modules=@(Get-ChildItem $hip -Recurse -Filter '*.hsaco');if($modules.Count -ne 62){throw 'Module count changed'}
 $lines=@($modules|Sort-Object FullName|ForEach-Object{$rel=$_.FullName.Substring($hip.Length+1).Replace('\','/');"$((Get-FileHash $_.FullName).Hash.ToLower())  $rel"})
 [IO.File]::WriteAllLines((Join-Path $game $sum),$lines,(New-Object Text.UTF8Encoding($false)))
 foreach($f in $payload.files){if((Get-FileHash (Join-Path $game $f.relative)).Hash.ToLower() -ne $f.sha256){throw 'Installed hash mismatch'}}
 foreach($f in $snapshot){if($f.name -eq 'deep_fast-packed.hsaco'){continue};if((Get-FileHash $f.path).Hash -ne $f.sha256){throw 'Protected file changed'}}
 @{backup=$backup;addon=(Get-FileHash "$game\dlss5-amd.addon64").Hash;modules=62;changed_modules=2;preserved_modules=60;direct_io=3;make_resident_every=60;swin_run=1;payload=$payload}|ConvertTo-Json -Depth 7|Set-Content "$root\installed.json"
 "INSTALLED backup=$backup"
}catch{Restore $backup;throw}

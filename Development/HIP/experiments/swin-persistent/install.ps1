param([string]$RestoreBackup='')
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
function Idle {if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^rtc_compile|^Magpie'}){throw 'Game/GPU lab busy'}}
function Restore($backup){
 $m=Get-Content "$backup\backup.json" -Raw|ConvertFrom-Json
 foreach($f in $m){$dst=Join-Path $game $f.relative;if($f.existed){Copy-Item (Join-Path $backup $f.relative) $dst -Force;if((Get-FileHash $dst).Hash -ne $f.sha256){throw 'Restore hash mismatch'}}elseif(Test-Path $dst){Remove-Item $dst}}
}
Idle
if($RestoreBackup){Restore $RestoreBackup;'RESTORED';exit 0}
$snapshot=Get-Content "$root\snapshot.json" -Raw|ConvertFrom-Json
foreach($f in $snapshot){if((Get-FileHash $f.path).Hash -ne $f.sha256){throw "Installed baseline changed: $($f.path)"}}
$payload=Get-Content "$root\payload\manifest.json" -Raw|ConvertFrom-Json
foreach($f in $payload.files){if((Get-FileHash (Join-Path "$root\payload" $f.source)).Hash.ToLower() -ne $f.sha256){throw 'Payload hash mismatch'}}
$flagsRel='DLSS5-AMD\native-game-flags.txt'
$sumRel='DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS'
$utf8=New-Object Text.UTF8Encoding($false,$true)
$oldFlags=$utf8.GetString([IO.File]::ReadAllBytes((Join-Path $game $flagsRel)))
foreach($expect in @(@('DLSS5_DIRECT_IO','3'),@('DLSS5_MAKE_RESIDENT_EVERY','60'))){$value=[regex]::Match($oldFlags,"(?m)^\s*$($expect[0])\s*=\s*(\d+)").Groups[1].Value;if($value -ne $expect[1]){throw "Preserve required flag $($expect[0])"}}
if($oldFlags -match '(?m)^\s*DLSS5_HIP_SWIN_RUN\s*='){throw 'New flag already present; inspect rather than overwrite'}
$backup="$root\backups\stellar-$(Get-Date -Format yyyyMMdd-HHmmss)"
New-Item -ItemType Directory -Force $backup|Out-Null
$targets=@($payload.files|ForEach-Object{$_.relative})+@($flagsRel,$sumRel)
$saved=@()
foreach($rel in $targets){
 $src=Join-Path $game $rel;$dst=Join-Path $backup $rel;$exists=Test-Path $src
 $sha='';if($exists){New-Item -ItemType Directory -Force (Split-Path -Parent $dst)|Out-Null;Copy-Item $src $dst;$sha=(Get-FileHash $src).Hash;if((Get-FileHash $dst).Hash -ne $sha){throw 'Backup hash mismatch'}}
 $saved+=@{relative=$rel;existed=$exists;sha256=$sha}
}
$saved|ConvertTo-Json -Depth 4|Set-Content "$backup\backup.json"
try{
 Idle
 foreach($f in $payload.files){Copy-Item (Join-Path "$root\payload" $f.source) (Join-Path $game $f.relative) -Force}
 $newline=if($oldFlags.Contains("`r`n")){"`r`n"}else{"`n"}
 $newFlags=$oldFlags+$(if($oldFlags.EndsWith("`n")){''}else{$newline})+'DLSS5_HIP_SWIN_RUN=1'+$newline
 [IO.File]::WriteAllBytes((Join-Path $game $flagsRel),$utf8.GetBytes($newFlags))
 $hip=Join-Path $game 'DLSS5-AMD\native-game-tiled-assets\HIP'
 $modules=@(Get-ChildItem $hip -Recurse -Filter '*.hsaco');if($modules.Count -ne 62){throw 'Expected sixty-two installed modules'}
 $lines=@($modules|Sort-Object FullName|ForEach-Object{$rel=$_.FullName.Substring($hip.Length+1).Replace('\','/');"$((Get-FileHash $_.FullName).Hash.ToLower())  $rel"})
 [IO.File]::WriteAllLines((Join-Path $game $sumRel),$lines,$utf8)
 foreach($f in $payload.files){if((Get-FileHash (Join-Path $game $f.relative)).Hash.ToLower() -ne $f.sha256){throw 'Installed payload mismatch'}}
 foreach($f in $snapshot){if($f.path -like '*dlss5-amd.addon64' -or $f.path -like '*native-game-flags.txt'){continue};if((Get-FileHash $f.path).Hash -ne $f.sha256){throw 'Protected file changed'}}
 if([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $game $flagsRel))) -cne [Convert]::ToBase64String($utf8.GetBytes($newFlags))){throw 'Flags readback mismatch'}
 @{backup=$backup;addon=(Get-FileHash "$game\dlss5-amd.addon64").Hash;modules=62;preserved_modules=60;direct_io=3;make_resident_every=60;swin_run=1;payload=$payload}|ConvertTo-Json -Depth 7|Set-Content "$root\installed.json"
 "INSTALLED backup=$backup"
}catch{Restore $backup;throw}

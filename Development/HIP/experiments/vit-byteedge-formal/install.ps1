param([switch]$Restore,[string]$Backup='')
$ErrorActionPreference='Stop';$root=$PSScriptRoot
$games=@('C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64','C:\XboxGames\Onimusha- Way of the Sword\Content')
$hip='DLSS5-AMD\native-game-tiled-assets\HIP';$exact='D:\DLSSNR-Lab\fast-tier\exact'
function Idle {& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'Game running / check failed'};if(Get-Process -EA 0|?{$_.ProcessName -match '^benchmark|^rt_bench|^runtime-smoke|^rtc_compile|^jobbench'}){throw 'lab busy'};if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -ne 'vit-byteedge-formal-20261004'){throw 'wrong lock'}}
function Rollback($b){foreach($idx in 0,1){$base=$games[$idx];foreach($f in (Get-Content "$b\game-$idx\manifest.json" -Raw|ConvertFrom-Json)){$dst=Join-Path $base $f.relative;if($f.existed){New-Item -ItemType Directory -Force (Split-Path $dst)|Out-Null;Copy-Item (Join-Path "$b\game-$idx" $f.relative) $dst -Force;if((Get-FileHash $dst).Hash -ne $f.sha256){throw 'restore mismatch'}}else{Remove-Item $dst -Force -EA 0}}};Copy-Item "$b\exact\*" $exact -Recurse -Force;'RESTORED'}
if($Restore){
 if(!$Backup){throw 'Backup required'}
 $lock='D:\DLSSNR-Lab\gpu.lock';$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$bytes=[Text.Encoding]::UTF8.GetBytes('vit-byteedge-formal-20261004');$f.Write($bytes,0,$bytes.Length);$f.Close()
 try{Idle;Rollback $Backup}finally{if((Get-Content $lock -Raw).Trim() -eq 'vit-byteedge-formal-20261004'){Remove-Item $lock -Force}}
 exit
}
$lock='D:\DLSSNR-Lab\gpu.lock';$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$bytes=[Text.Encoding]::UTF8.GetBytes('vit-byteedge-formal-20261004');$f.Write($bytes,0,$bytes.Length);$f.Close()
Idle
foreach($check in @(@{n='normal-0';count=7},@{n='normal-1';count=7},@{n='roll-0';count=2},@{n='roll-1';count=2})){if(@(Select-String -Path "$root\$($check.n).log" -Pattern '^SAME').Count -ne $check.count){throw 'regression incomplete'}}
if(!(Select-String -Path "$root\rt-stage.log" -Pattern 'RT_DONE')){throw 'runtime verification incomplete'}
$b="$root\backups\$(Get-Date -Format yyyyMMdd-HHmmss)";New-Item -ItemType Directory -Force $b|Out-Null;Copy-Item $exact "$b\exact" -Recurse
$configHashes=@{}
foreach($idx in 0,1){$base=$games[$idx];$bd="$b\game-$idx";New-Item -ItemType Directory -Force $bd|Out-Null
 $rels=@('dlss5-amd.addon64','LmxxfNrRuntime.dll','_storage_\LmxxfNrRuntime.dll','DLSS5-AMD\default-config.txt','DLSS5-AMD\custom-config.txt','DLSS5-AMD\native-game-flags.txt',"$hip\SHA256SUMS")
 $rels+=@(Get-ChildItem "$root\HIP" -Filter '*.hsaco' -Recurse|%{"$hip\$($_.FullName.Substring(("$root\HIP\").Length))"})
 $rels+=@(Get-ChildItem "$base\$hip" -Filter '*.hsaco' -Recurse|%{$_.FullName.Substring($base.Length+1)})
 $manifest=@();foreach($rel in $rels|Sort-Object -Unique){$src=Join-Path $base $rel;$exists=Test-Path $src;$sha='';if($exists){$sha=(Get-FileHash $src).Hash;$dst=Join-Path $bd $rel;New-Item -ItemType Directory -Force (Split-Path $dst)|Out-Null;Copy-Item $src $dst;if((Get-FileHash $dst).Hash -ne $sha){throw 'backup mismatch'}};$manifest+=@{relative=$rel;existed=$exists;sha256=$sha}}
 $manifest|ConvertTo-Json -Depth 4|Set-Content "$bd\manifest.json"
 foreach($name in 'default-config.txt','custom-config.txt','native-game-flags.txt'){$configHashes["$idx-$name"]=(Get-FileHash "$base\DLSS5-AMD\$name").Hash}
}
$rollbackCommand="& '$root\install.ps1' -Restore -Backup '$b'"
[IO.File]::WriteAllText("$b\rollback.ps1",$rollbackCommand)
try{foreach($idx in 0,1){Idle;$base=$games[$idx]
 if(Test-Path "$base\dlss5-amd.addon64"){Copy-Item "$root\dlss5-amd.addon64" "$base\dlss5-amd.addon64" -Force}
 foreach($rel in 'LmxxfNrRuntime.dll','_storage_\LmxxfNrRuntime.dll'){if(Test-Path "$base\$rel"){Copy-Item "$root\LmxxfNrRuntime.dll" "$base\$rel" -Force}}
 foreach($a in 'gfx1200','gfx1201'){Copy-Item "$root\HIP\$a\*.hsaco" "$base\$hip\$a" -Force;foreach($f in Get-ChildItem "$root\HIP\$a" -Filter '*.hsaco'){if((Get-FileHash "$base\$hip\$a\$($f.Name)").Hash -ne (Get-FileHash $f.FullName).Hash){throw 'module readback'}}}

 $lines=@(Get-ChildItem "$base\$hip" -Recurse -Filter '*.hsaco'|Sort-Object FullName|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring(("$base\$hip\").Length).Replace('\','/'))"});if($lines.Count -ne 76){throw "module count $($lines.Count)"};[IO.File]::WriteAllLines("$base\$hip\SHA256SUMS",$lines)
 foreach($name in 'default-config.txt','custom-config.txt','native-game-flags.txt'){if((Get-FileHash "$base\DLSS5-AMD\$name").Hash -ne $configHashes["$idx-$name"]){throw 'user config changed'}}
 foreach($rel in 'dlss5-amd.addon64','LmxxfNrRuntime.dll','_storage_\LmxxfNrRuntime.dll'){if(Test-Path "$base\$rel"){$expected=if($rel -match 'Runtime'){"$root\LmxxfNrRuntime.dll"}else{"$root\dlss5-amd.addon64"};if((Get-FileHash "$base\$rel").Hash -ne (Get-FileHash $expected).Hash){throw 'binary readback'}}}
 "INSTALLED $base";foreach($name in 'dlss5-amd.addon64','LmxxfNrRuntime.dll',"$hip\SHA256SUMS"){if(Test-Path "$base\$name"){Get-FileHash "$base\$name"|Format-List Path,Hash}}
}
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$root\HIP\$a\*.hsaco" "$exact\$a" -Force}
foreach($idx in 0,1){$name=if($idx -eq 0){'stellar'}else{'oni'};Copy-Item "$($games[$idx])\DLSS5-AMD\custom-config.txt" "$exact\$name-custom-config.txt" -Force;Copy-Item "$($games[$idx])\$hip\SHA256SUMS" "$exact\$name-SHA256SUMS" -Force;Copy-Item "$($games[$idx])\DLSS5-AMD\native-game-flags.txt" "$exact\$name-flags.txt" -Force}
if((Get-FileHash "$($games[0])\$hip\SHA256SUMS").Hash -ne (Get-FileHash "$($games[1])\$hip\SHA256SUMS").Hash){throw 'dual game SUMS mismatch'}
}catch{Rollback $b;throw}
"BACKUP $b";'INSTALL_DONE configuration preserved both_games'

if((Get-Content $lock -Raw).Trim() -eq 'vit-byteedge-formal-20261004'){Remove-Item $lock -Force}

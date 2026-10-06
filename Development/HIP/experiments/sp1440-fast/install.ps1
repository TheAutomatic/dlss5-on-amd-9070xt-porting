$ErrorActionPreference='Stop';$r=$PSScriptRoot;$lock='D:\DLSSNR-Lab\gpu.lock'
$games=@('C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64','C:\XboxGames\Onimusha- Way of the Sword\Content')
function Idle{& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}}
Idle;$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$bytes=[Text.Encoding]::UTF8.GetBytes('sp1440-fast-20261005');$f.Write($bytes,0,$bytes.Length);$f.Close()
try{
$b="$r\backups\$(Get-Date -Format yyyyMMdd-HHmmss)";New-Item -ItemType Directory -Force $b|Out-Null;$before=@{}
foreach($i in 0,1){$g=$games[$i];New-Item -ItemType Directory -Force "$b\game-$i"|Out-Null
foreach($n in 'default-config.txt','custom-config.txt','native-game-flags.txt'){$p="$g\DLSS5-AMD\$n";if(Test-Path $p){Copy-Item $p "$b\game-$i\$n";$before["$i-$n"]=(Get-FileHash $p).Hash}}
$before["$i-modules"]=(Get-FileHash "$g\DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS").Hash
}
foreach($i in 0,1){$g=$games[$i];Copy-Item "$g\DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS" "$b\game-$i\SHA256SUMS"}
Copy-Item "$($games[0])\dlss5-amd.addon64" "$b\game-0\dlss5-amd.addon64"
Copy-Item "$($games[1])\LmxxfNrRuntime.dll" "$b\game-1\LmxxfNrRuntime.dll"
Copy-Item "$($games[1])\_storage_\LmxxfNrRuntime.dll" "$b\game-1\storage-LmxxfNrRuntime.dll"
$rollback=@('$ErrorActionPreference="Stop"',"& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk",'if($LASTEXITCODE -ne 1){throw "game active"}',"Copy-Item '$b\game-0\dlss5-amd.addon64' '$($games[0])\dlss5-amd.addon64' -Force","Copy-Item '$b\game-1\LmxxfNrRuntime.dll' '$($games[1])\LmxxfNrRuntime.dll' -Force","Copy-Item '$b\game-1\storage-LmxxfNrRuntime.dll' '$($games[1])\_storage_\LmxxfNrRuntime.dll' -Force")
foreach($i in 0,1){$g=$games[$i];foreach($arch in 'gfx1200','gfx1201'){$rollback+="Remove-Item '$g\DLSS5-AMD\native-game-tiled-assets\HIP\$arch\swin-persistent-fast.hsaco' -ErrorAction SilentlyContinue"};$rollback+="Copy-Item '$b\game-$i\SHA256SUMS' '$g\DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS' -Force"}
[IO.File]::WriteAllLines("$b\rollback.ps1",$rollback)
foreach($i in 0,1){$g=$games[$i];$hip="$g\DLSS5-AMD\native-game-tiled-assets\HIP";$old=@(Get-Content "$hip\SHA256SUMS");if($old.Count -ne 76){throw 'baseline not 76 modules'};foreach($arch in 'gfx1200','gfx1201'){Idle;$src="$r\$arch.hsaco";Copy-Item $src "$hip\$arch\swin-persistent-fast.hsaco" -Force;if((Get-FileHash $src).Hash -ne (Get-FileHash "$hip\$arch\swin-persistent-fast.hsaco").Hash){throw 'twin readback'}};foreach($line in $old){if((Get-FileHash (Join-Path $hip $line.Substring(66))).Hash.ToLower() -ne $line.Substring(0,64).ToLower()){throw 'old76 changed'}};$sums=@(Get-ChildItem $hip -Recurse -Filter *.hsaco|Sort-Object FullName|%{(Get-FileHash $_.FullName).Hash.ToLower()+'  '+$_.FullName.Substring($hip.Length+1).Replace('\','/')});if($sums.Count -ne 78){throw 'new78 count'};[IO.File]::WriteAllLines("$hip\SHA256SUMS",$sums)}
Idle;Copy-Item "$r\sp-fast.addon64" "$($games[0])\dlss5-amd.addon64" -Force
Idle;Copy-Item "$r\sp-fast.dll" "$($games[1])\LmxxfNrRuntime.dll" -Force
Idle;Copy-Item "$r\sp-fast.dll" "$($games[1])\_storage_\LmxxfNrRuntime.dll" -Force
$expectedAddon=(Get-FileHash "$r\sp-fast.addon64").Hash;$expectedRuntime=(Get-FileHash "$r\sp-fast.dll").Hash
if((Get-FileHash "$($games[0])\dlss5-amd.addon64").Hash -ne $expectedAddon){throw 'addon readback'}
foreach($n in 'LmxxfNrRuntime.dll','_storage_\LmxxfNrRuntime.dll'){if((Get-FileHash "$($games[1])\$n").Hash -ne $expectedRuntime){throw 'runtime readback'}}
foreach($i in 0,1){$g=$games[$i];foreach($n in 'default-config.txt','custom-config.txt','native-game-flags.txt'){if($before.ContainsKey("$i-$n") -and (Get-FileHash "$g\DLSS5-AMD\$n").Hash -ne $before["$i-$n"]){throw 'config changed'}}}
$record=[ordered]@{backup=$b;addon=$expectedAddon;runtime=$expectedRuntime;config_unchanged=$true;old76_unchanged=$true;module_count=78;module_sums=(Get-FileHash "$($games[0])\DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS").Hash;before=$before}
$record|ConvertTo-Json -Depth 4|Set-Content "$r\install.json"
foreach($arch in 'gfx1200','gfx1201'){Copy-Item "$r\$arch.hsaco" "D:\DLSSNR-Lab\fast-tier\exact\$arch\swin-persistent-fast.hsaco" -Force}
Copy-Item "$($games[0])\DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS" 'D:\DLSSNR-Lab\fast-tier\exact\stellar-SHA256SUMS' -Force
Copy-Item "$($games[1])\DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS" 'D:\DLSSNR-Lab\fast-tier\exact\oni-SHA256SUMS' -Force
Copy-Item "$r\install.json" 'D:\DLSSNR-Lab\fast-tier\exact\host-payload.json' -Force
"INSTALL_DONE backup=$b addon=$expectedAddon runtime=$expectedRuntime CONFIG_UNCHANGED_OLD76_UNCHANGED_NEW78"
}finally{if((Test-Path $lock) -and (Get-Content $lock -Raw).Trim() -eq 'sp1440-fast-20261005'){Remove-Item $lock}}

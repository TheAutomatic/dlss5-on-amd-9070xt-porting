$ErrorActionPreference='Stop';$r=$PSScriptRoot;$lock='D:\DLSSNR-Lab\gpu.lock'
$games=@('C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64','C:\XboxGames\Onimusha- Way of the Sword\Content')
function Idle{& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}}
Idle;$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$bytes=[Text.Encoding]::UTF8.GetBytes('final-output-direct-20261005');$f.Write($bytes,0,$bytes.Length);$f.Close()
try{
$b="$r\backups\$(Get-Date -Format yyyyMMdd-HHmmss)";New-Item -ItemType Directory -Force $b|Out-Null;$before=@{}
foreach($i in 0,1){$g=$games[$i];New-Item -ItemType Directory -Force "$b\game-$i"|Out-Null
foreach($n in 'default-config.txt','custom-config.txt','native-game-flags.txt'){$p="$g\DLSS5-AMD\$n";if(Test-Path $p){Copy-Item $p "$b\game-$i\$n";$before["$i-$n"]=(Get-FileHash $p).Hash}}
$before["$i-modules"]=(Get-FileHash "$g\DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS").Hash
}
Copy-Item "$($games[0])\dlss5-amd.addon64" "$b\game-0\dlss5-amd.addon64"
Copy-Item "$($games[1])\LmxxfNrRuntime.dll" "$b\game-1\LmxxfNrRuntime.dll"
Copy-Item "$($games[1])\_storage_\LmxxfNrRuntime.dll" "$b\game-1\storage-LmxxfNrRuntime.dll"
$rollback=@('$ErrorActionPreference="Stop"',"& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk",'if($LASTEXITCODE -ne 1){throw "game active"}',"Copy-Item '$b\game-0\dlss5-amd.addon64' '$($games[0])\dlss5-amd.addon64' -Force","Copy-Item '$b\game-1\LmxxfNrRuntime.dll' '$($games[1])\LmxxfNrRuntime.dll' -Force","Copy-Item '$b\game-1\storage-LmxxfNrRuntime.dll' '$($games[1])\_storage_\LmxxfNrRuntime.dll' -Force")
[IO.File]::WriteAllLines("$b\rollback.ps1",$rollback)
Idle;Copy-Item "$r\direct.addon64" "$($games[0])\dlss5-amd.addon64" -Force
Idle;Copy-Item "$r\direct.dll" "$($games[1])\LmxxfNrRuntime.dll" -Force
Idle;Copy-Item "$r\direct.dll" "$($games[1])\_storage_\LmxxfNrRuntime.dll" -Force
$expectedAddon=(Get-FileHash "$r\direct.addon64").Hash;$expectedRuntime=(Get-FileHash "$r\direct.dll").Hash
if((Get-FileHash "$($games[0])\dlss5-amd.addon64").Hash -ne $expectedAddon){throw 'addon readback'}
foreach($n in 'LmxxfNrRuntime.dll','_storage_\LmxxfNrRuntime.dll'){if((Get-FileHash "$($games[1])\$n").Hash -ne $expectedRuntime){throw 'runtime readback'}}
foreach($i in 0,1){$g=$games[$i];foreach($n in 'default-config.txt','custom-config.txt','native-game-flags.txt'){if($before.ContainsKey("$i-$n") -and (Get-FileHash "$g\DLSS5-AMD\$n").Hash -ne $before["$i-$n"]){throw 'config changed'}};if((Get-FileHash "$g\DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS").Hash -ne $before["$i-modules"]){throw 'modules changed'}}
$record=[ordered]@{backup=$b;addon=$expectedAddon;runtime=$expectedRuntime;config_and_modules_unchanged=$true;before=$before}
$record|ConvertTo-Json -Depth 4|Set-Content "$r\install.json"
Copy-Item "$r\install.json" 'D:\DLSSNR-Lab\fast-tier\exact\host-payload.json' -Force
"INSTALL_DONE backup=$b addon=$expectedAddon runtime=$expectedRuntime CONFIG_MODULES_UNCHANGED"
}finally{if((Test-Path $lock) -and (Get-Content $lock -Raw).Trim() -eq 'final-output-direct-20261005'){Remove-Item $lock}}

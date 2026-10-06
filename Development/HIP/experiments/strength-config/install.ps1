$ErrorActionPreference='Stop';$root=$PSScriptRoot;$g='C:\XboxGames\Onimusha- Way of the Sword\Content';$lock='D:\DLSSNR-Lab\gpu.lock'
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active; candidate retained'}
$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$f.Close()
try{$b="$root\backups\$(Get-Date -Format yyyyMMdd-HHmmss)";New-Item -ItemType Directory -Force "$b\_storage_","$b\DLSS5-AMD"|Out-Null;$cfg=@{};foreach($n in 'default-config.txt','custom-config.txt','native-game-flags.txt'){Copy-Item "$g\DLSS5-AMD\$n" "$b\DLSS5-AMD\$n";$cfg[$n]=(Get-FileHash "$g\DLSS5-AMD\$n").Hash}
foreach($p in 'LmxxfNrRuntime.dll','_storage_\LmxxfNrRuntime.dll'){Copy-Item "$g\$p" "$b\$p";if((Get-FileHash "$g\$p").Hash -ne (Get-FileHash "$b\$p").Hash){throw 'backup mismatch'}}
[IO.File]::WriteAllText("$b\rollback.ps1","Copy-Item '$b\LmxxfNrRuntime.dll' '$g\LmxxfNrRuntime.dll' -Force`r`nCopy-Item '$b\_storage_\LmxxfNrRuntime.dll' '$g\_storage_\LmxxfNrRuntime.dll' -Force`r`n")
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game started; no change'}
try{foreach($p in 'LmxxfNrRuntime.dll','_storage_\LmxxfNrRuntime.dll'){Copy-Item "$root\new.dll" "$g\$p" -Force;if((Get-FileHash "$g\$p").Hash -ne (Get-FileHash "$root\new.dll").Hash){throw 'readback mismatch'}};foreach($n in $cfg.Keys){if((Get-FileHash "$g\DLSS5-AMD\$n").Hash -ne $cfg[$n]){throw 'configuration changed'}}}catch{& "$b\rollback.ps1";throw}
"INSTALLED runtime=$((Get-FileHash "$g\LmxxfNrRuntime.dll").Hash) BACKUP=$b CONFIG_UNCHANGED=1"
}finally{Remove-Item $lock -Force}

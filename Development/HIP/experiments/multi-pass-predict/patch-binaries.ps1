$ErrorActionPreference='Stop';$root=$PSScriptRoot
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -ne 'multi-pass-predict-20261004'){throw 'wrong lock'}
$games=@('C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64','C:\XboxGames\Onimusha- Way of the Sword\Content')
foreach($g in $games){foreach($n in 'dlss5-amd.addon64','LmxxfNrRuntime.dll','_storage_\LmxxfNrRuntime.dll'){if(Test-Path "$g\$n"){$src=if($n -match 'Runtime'){"$root\LmxxfNrRuntime.dll"}else{"$root\dlss5-amd.addon64"};Copy-Item $src "$g\$n" -Force;if((Get-FileHash "$g\$n").Hash -ne (Get-FileHash $src).Hash){throw 'readback mismatch'};Get-FileHash "$g\$n"|Format-List Path,Hash}}}
'PATCH_DONE'

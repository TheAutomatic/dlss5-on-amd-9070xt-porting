$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mochizuki-022'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets\HIP'
if(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^ledger$'}){throw 'GPU busy'}
if(Test-Path "$r\modules-A"){throw 'Baseline already exists'}
New-Item -ItemType Directory "$r\modules-A"|Out-Null
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$g\$a" "$r\modules-A\$a" -Recurse}
Copy-Item 'D:\DLSSNR-Lab\hip-backend\c512-round1\benchmark.exe' "$r\benchmark.exe"
& "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\census" -Targets gfx1201
if($LASTEXITCODE){throw 'Census build failed'}
Compress-Archive -Path "$r\census\*.s","$r\census\*.hsaco","$r\census\*.json" -DestinationPath "$r\census.zip" -Force
Compress-Archive -Path "$r\modules-A\gfx1201\*.hsaco" -DestinationPath "$r\baseline.zip" -Force
'CENSUS_READY'

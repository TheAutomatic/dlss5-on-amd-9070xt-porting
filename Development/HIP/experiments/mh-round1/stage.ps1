$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mh-round1'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets\HIP'
if(Get-Process SB-Win64-Shipping,LOP-Win64-Shipping,OnimushaWotS,re9,benchmark -ErrorAction SilentlyContinue){throw 'GPU busy'}
if(Test-Path "$r\modules-A"){throw 'Baseline exists'}
New-Item -ItemType Directory "$r\modules-A"|Out-Null
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$g\$a" "$r\modules-A\$a" -Recurse}
Copy-Item 'D:\DLSSNR-Lab\hip-backend\vit-bytestream\benchmark.exe' "$r\benchmark.exe"
& "$r\hip\build-modules.ps1" -SourceDir "$r\hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-A" -Only c64-wave2 -ExtraDefines @('W2_BYTE_INPUT_LOADS 0','W2_RTZ_PAIR 0','W2_DIRECT_COORDS 0','W2_FULL_WINDOW 0','W2_DIRECT_FEATURE 0')
if($LASTEXITCODE){throw 'baseline compile'}
$env:RTC_EXTRA_OPTS='-gline-tables-only'
& 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' "$r\base-debug.hsaco" "$r\build-A\gfx1201\c64-wave2.generated.hip" comgr gfx1201
if($LASTEXITCODE){throw 'debug compile'}

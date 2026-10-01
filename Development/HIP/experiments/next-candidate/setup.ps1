# next-candidate (2026-10-02): build main's full recipe (-RowOpts -PrebuiltDir pre23) = 62 modules; harness from rebuild-baseline (idle pinned).
# base = 0.39 installed: Stellar gfx1201 modules + installed assets (minus HIP); host bench built from HEAD (host source == installed add-on 053C3589 source).
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\next-candidate-20261002';$s='D:\DLSSNR-Lab\hip-backend\rebuild-baseline-20261001'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets'
& "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-next" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -RowOpts -PrebuiltDir "$root\pre23"|Out-Null
foreach($a in 'gfx1200','gfx1201'){"build $a $(@(Get-ChildItem "$root\build-next\$a" -Filter *.hsaco).Count)"}
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1','full.ps1'){(Get-Content "$s\$f" -Raw).Replace('rebuild-baseline-20261001','next-candidate-20261002')|Set-Content "$root\$f"}
if((Get-Content "$root\regression.ps1" -Raw) -notmatch 'ADAPTIVE_IDLE_MS=1000000000'){throw 'idle pin missing'}
foreach($n in 'A','N'){Remove-Item "$root\flat-$n" -Recurse -Force -EA 0;New-Item -ItemType Directory "$root\flat-$n"|Out-Null}
Copy-Item "$g\HIP\gfx1201\*.hsaco" "$root\flat-A";Copy-Item "$root\build-next\gfx1201\*.hsaco" "$root\flat-N"
Remove-Item "$root\assets-base" -Recurse -Force -EA 0;New-Item -ItemType Directory "$root\assets-base"|Out-Null;Get-ChildItem $g|?{$_.Name -ne 'HIP'}|%{Copy-Item $_.FullName "$root\assets-base" -Recurse}
Copy-Item "$root\bin\benchmark-N.exe" "$root\benchmark-base.exe" -Force;Copy-Item "$root\bin\benchmark-N.exe","$root\bin\benchmark-Nroll.exe" $root -Force
"flatA $(@(gci "$root\flat-A" -Filter *.hsaco).Count) flatN $(@(gci "$root\flat-N" -Filter *.hsaco).Count)"
'SETUP_DONE'

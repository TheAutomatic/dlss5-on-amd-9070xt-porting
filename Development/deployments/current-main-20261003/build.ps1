$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\current-main-20261003'
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie
if($LASTEXITCODE -ne 1){throw 'game running / game check failed'}
if(Get-Process|?{$_.ProcessName -match '^benchmark|^rt_bench|^rtc_compile|^runtime-smoke|^jobbench'}){throw 'lab busy'}
$lock='D:\DLSSNR-Lab\gpu.lock'
$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
$b=[Text.Encoding]::UTF8.GetBytes('current-main-20261003');$f.Write($b,0,$b.Length);$f.Close()
Expand-Archive 'D:\DLSSNR-Lab\current-main-20261003-src.zip' $root -Force
Expand-Archive 'D:\DLSSNR-Lab\current-main-20261003-llvm23.zip' "$root\llvm23" -Force
Copy-Item 'D:\DLSSNR-Lab\hip-backend\fast-vit-20261003\src\rtc_compile.exe' "$root\src\rtc_compile.exe"
& "$root\src\build-modules.ps1" -OutputDir "$root\HIP" -Compiler "$root\src\rtc_compile.exe" -SourceDir "$root\src" -RowOpts -PrebuiltDir "$root\llvm23" *> "$root\build-modules.log"
if(!$?){throw 'module build failed'}
'BUILD_DONE'

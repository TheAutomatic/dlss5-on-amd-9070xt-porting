$ErrorActionPreference='Stop';$root=$PSScriptRoot
& "$root\src\build-modules.ps1" -SourceDir "$root\src" -Compiler 'D:\DLSSNR-Lab\multi-pass-predict-20261004\rtc_compile.exe' -OutputDir "$root\HIP" -Only 'c512-m32-deep' -Targets @('gfx1200','gfx1201') -RowOpts *> "$root\canonical-build.log"
if(!$?){throw 'canonical build failed'}
Copy-Item "$root\HIP\gfx1201\c512-m32-deep.hsaco" "$root\flat-N\c512-m32-deep.hsaco" -Force
'BUILD_DONE'

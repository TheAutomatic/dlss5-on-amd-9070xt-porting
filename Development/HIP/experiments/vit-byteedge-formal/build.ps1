$ErrorActionPreference='Stop';$root=$PSScriptRoot
foreach($name in 'vit-stream','vit-stream-fast'){
 & "$root\src\build-modules.ps1" -SourceDir "$root\src" -Compiler 'D:\DLSSNR-Lab\multi-pass-predict-20261004\rtc_compile.exe' -OutputDir "$root\HIP" -Only $name -Targets @('gfx1200','gfx1201') -RowOpts *> "$root\$name-canonical-build.log"
 if(!$?){throw "canonical compile failed $name"}
}
'BUILD_DONE canonical recipe'

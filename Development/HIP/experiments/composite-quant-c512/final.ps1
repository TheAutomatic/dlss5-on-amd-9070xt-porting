# Recipe build (src.zip with C512_F_MASK 1 in the c512-m32-deep / deep_fast-packed recipes), both arches.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\composite-quant-c512-20260930'
if(Test-Path "$root\src"){Remove-Item "$root\src" -Recurse -Force};Expand-Archive "$root\src.zip" "$root\src" -Force
foreach($m in 'c512-m32-deep','deep_fast-packed'){foreach($arch in 'gfx1200','gfx1201'){
 & "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-final\$arch" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets $arch -Only $m
 if(!$?){throw 'compile failed'}}}
Get-ChildItem "$root\build-final" -Recurse -Filter '*.hsaco'|ForEach-Object{"$($_.FullName.Substring($root.Length+1)) $((Get-FileHash $_.FullName).Hash)"}
'FINAL_DONE'

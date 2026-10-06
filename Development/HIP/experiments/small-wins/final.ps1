# Recipe build (new src.zip) of the three changed modules, both arches; flat-final = flat-A + gfx1201 finals; one confirmation ABBA round vs flat-A.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\small-wins-20260930'
if(Test-Path "$root\src"){Remove-Item "$root\src" -Recurse -Force};Expand-Archive "$root\src.zip" "$root\src" -Force
foreach($m in 'c32-wave1','c512-m32-deep','vit-stream'){foreach($arch in 'gfx1200','gfx1201'){
 & "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-final\$arch" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets $arch -Only $m
 if(!$?){throw 'compile failed'}}}
New-Item -ItemType Directory -Force "$root\flat-final"|Out-Null;Copy-Item "$root\flat-A\*.hsaco" "$root\flat-final" -Force
Get-ChildItem "$root\build-final\gfx1201" -Recurse -Filter '*.hsaco'|ForEach-Object{Copy-Item $_.FullName "$root\flat-final" -Force}
Get-ChildItem "$root\build-final" -Recurse -Filter '*.hsaco'|ForEach-Object{"$($_.FullName.Substring($root.Length+1)) $((Get-FileHash $_.FullName).Hash)"}
& "$root\full.ps1" -Set final -Cand base -RollHost Proll -Rounds 1 *> "$root\full-final.log"
'FINAL_DONE'

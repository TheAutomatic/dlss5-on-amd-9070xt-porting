$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\c512-proj-share-20260929'
if(Test-Path "$root\src"){Remove-Item "$root\src" -Recurse -Force}
Expand-Archive "$root\src.zip" "$root\src" -Force
foreach($arch in 'gfx1200','gfx1201'){foreach($en in 0,1){
 if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rtc_compile|^jobbench|^Magpie'}){throw 'GPU busy'}
 & "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-$en\$arch" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets $arch -Only multihead-fast-padded-wave-packed -ExtraDefines @("C512_PROJ_M32 $en")
 if(!$?){throw 'compile failed'}
}}
foreach($arch in 'gfx1200','gfx1201'){foreach($en in 0,1){$f=Get-ChildItem "$root\build-$en\$arch" -Recurse -Filter 'multihead-fast-padded-wave-packed.hsaco'|Select-Object -First 1;"$arch M32=$en $((Get-FileHash $f.FullName).Hash) $($f.FullName)"}
 "$arch installed $((Get-FileHash "$root\baseline\$arch\multihead-fast-padded-wave-packed.hsaco").Hash)"}
$f=Get-ChildItem "$root\build-1\gfx1201" -Recurse -Filter 'multihead-fast-padded-wave-packed.hsaco'|Select-Object -First 1
Copy-Item $f.FullName "$root\flat-P\multihead-fast-padded-wave-packed.hsaco" -Force

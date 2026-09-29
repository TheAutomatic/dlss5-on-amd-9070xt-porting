param([string]$Name,[string[]]$Defs)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\c32-align-20260930'
$Defs=@($Defs|ForEach-Object{$_ -split ","}|Where-Object{$_}|ForEach-Object{$_ -replace "=", " "})
foreach($arch in 'gfx1200','gfx1201'){
 & "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-$Name\$arch" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets $arch -Only multihead-fast-padded-wave-packed -ExtraDefines $Defs
 if(!$?){throw 'compile failed'}
 $f=Get-ChildItem "$root\build-$Name\$arch" -Recurse -Filter 'multihead-fast-padded-wave-packed.hsaco'|Select-Object -First 1
 "$arch $Name $((Get-FileHash $f.FullName).Hash)"}
'BMH_DONE'

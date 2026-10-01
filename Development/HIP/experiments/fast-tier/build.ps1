param([string]$Name,[string]$Module,[string[]]$Defs=@())
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\fast-tier-20261001'
$Defs=@($Defs|ForEach-Object{$_ -split ","}|Where-Object{$_}|ForEach-Object{$_ -replace "=", " "})
if(Test-Path "$root\src.zip"){Remove-Item "$root\src" -Recurse -Force -EA 0;Expand-Archive "$root\src.zip" "$root\src" -Force;Remove-Item "$root\src.zip"}
& "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-$Name\gfx1201" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets gfx1201 -Only $Module -ExtraDefines $Defs|Out-Null
$f=Get-ChildItem "$root\build-$Name\gfx1201" -Recurse -Filter "$Module.hsaco"|Select-Object -First 1
"$Name $Module $((Get-FileHash $f.FullName).Hash.Substring(0,8)) installed $((Get-FileHash "$root\flat-A\$Module.hsaco").Hash.Substring(0,8))"

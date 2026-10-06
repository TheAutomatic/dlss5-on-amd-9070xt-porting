param([string]$Name,[string]$Module='c512-m32-deep',[string]$Defs='',[switch]$Both)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\ideas-yi-20261002'
$D=@($Defs -split ','|?{$_}|%{$_ -replace '=',' '})
$arches=if($Both){'gfx1200','gfx1201'}else{'gfx1201'}
foreach($arch in $arches){& "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-$Name\$arch" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets $arch -Only $Module -ExtraDefines $D -RowOpts|Out-Null
 "$arch $Name $((Get-FileHash "$root\build-$Name\$arch\$Module.hsaco").Hash.Substring(0,8))"}

# build.ps1 -Name X -Module m -Defs 'A 1,B 2' [-Both]   (production recipe defines + ExtraDefines)
param([string]$Name,[string]$Module='deep_fast-packed',[string]$Defs='',[switch]$Both)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\bitexact-pm-20261001'
$D=@($Defs -split ','|?{$_}|%{$_ -replace '=',' '})
$arches=if($Both){'gfx1200','gfx1201'}else{'gfx1201'}
foreach($arch in $arches){& "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-$Name\$arch" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets $arch -Only $Module -ExtraDefines $D|Out-Null
 "$arch $Name $Module $((Get-FileHash "$root\build-$Name\$arch\$Module.hsaco").Hash.Substring(0,8))"}
'BUILD_DONE'

# b.ps1 -Name X -Module m -Defs 'A 1,B 2' [-Both] : build into build-X\<arch>
param([string]$Name,[string]$Module='c512-m32-mh',[string]$Defs='',[switch]$Both)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\c512-qkv-pipeline-20261001'
$D=@($Defs -split ','|?{$_}|%{$_ -replace '=',' '})
$arches=if($Both){'gfx1200','gfx1201'}else{'gfx1201'}
foreach($arch in $arches){& "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-$Name\$arch" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets $arch -Only $Module -ExtraDefines $D|Out-Null
 "$arch $Name $((Get-FileHash "$root\build-$Name\$arch\$Module.hsaco").Hash)"}

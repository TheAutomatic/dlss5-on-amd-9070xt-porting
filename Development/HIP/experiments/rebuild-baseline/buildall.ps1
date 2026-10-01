# buildall.ps1 -Name X [-Defs 'A 1,B 2']: full recipe build (31 modules x gfx1200/gfx1201) from src\ into build-X
param([string]$Name='head',[string]$Defs='',[string]$Only='')
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\rebuild-baseline-20261001'
$D=@($Defs -split ','|?{$_}|%{$_ -replace '=',' '})
if(Test-Path "$root\src.zip"){Remove-Item "$root\src" -Recurse -Force -EA 0;Expand-Archive "$root\src.zip" "$root\src" -Force;Remove-Item "$root\src.zip"}
$a=@{SourceDir="$root\src";OutputDir="$root\build-$Name";Compiler='D:\DLSSNR-Lab\build-0927\rtc_compile.exe';ExtraDefines=$D}
if($Only){$a.Only=$Only}
& "$root\src\build-modules.ps1" @a|Out-Null
'BUILD_DONE'

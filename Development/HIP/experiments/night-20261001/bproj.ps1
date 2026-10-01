# bproj.ps1: unzip src.zip, build multihead-fast-padded-wave-packed (gfx1201) for C512_PROJ_ABLATE 0/1/2/4/6/7 into proj\build-a<N>
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\night-20261001\proj'
if(Test-Path "$root\src.zip"){Remove-Item "$root\src" -Recurse -Force -EA 0;Expand-Archive "$root\src.zip" "$root\src" -Force;Remove-Item "$root\src.zip"}
foreach($n in 0,1,2,4,6,7){& "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-a$n\gfx1201" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets gfx1201 -Only multihead-fast-padded-wave-packed -ExtraDefines @("C512_PROJ_ABLATE $n")|Out-Null
 "a$n $((Get-FileHash "$root\build-a$n\gfx1201\multihead-fast-padded-wave-packed.hsaco").Hash.Substring(0,8))"}

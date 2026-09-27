# Source-level follow-up of the hand edit: rebuild only c64-wave2 with the production recipe plus -ExtraDefines
# (Q = W2_PACK8 6: +0 applied at store so x*y+0 contracts into fma), then stage a full 29-module set via mkset.ps1.
param([string]$Name='Q',[string[]]$Defines=@('W2_PACK8 6'))
$ErrorActionPreference='Stop';$d=Split-Path -Parent $MyInvocation.MyCommand.Path
$rtc='D:\DLSSNR-Lab\dual-arch-src\rtc_compile.exe';$out="$d\build-$Name"
& "$d\hip\build-modules.ps1" -Compiler $rtc -SourceDir "$d\hip" -OutputDir $out -Targets gfx1201 -Only c64-wave2 -ExtraDefines $Defines|Out-Null
$h=if(Test-Path "$out\gfx1201\c64-wave2.hsaco"){"$out\gfx1201\c64-wave2.hsaco"}else{"$out\c64-wave2.hsaco"}
& "$d\mkset.ps1" -Name $Name -Hsaco $h

param([string]$Name,[string]$Hsaco)
$ErrorActionPreference='Stop';$d='D:\DLSSNR-Lab\hip-backend\c64-hand-asm';$p='D:\DLSSNR-Lab\hip-backend\pack8\modules-P\gfx1201'
if(!(Test-Path "$d\modules-P\gfx1201")){New-Item -ItemType Directory -Force "$d\modules-P\gfx1201"|Out-Null;Copy-Item "$p\*.hsaco" "$d\modules-P\gfx1201\"}
New-Item -ItemType Directory -Force "$d\modules-$Name\gfx1201"|Out-Null;Copy-Item "$p\*.hsaco" "$d\modules-$Name\gfx1201\" -Force
Copy-Item $Hsaco "$d\modules-$Name\gfx1201\c64-wave2.hsaco" -Force
"set ${Name}: " + @(Get-ChildItem "$d\modules-$Name\gfx1201" -Filter *.hsaco).Count + " modules"

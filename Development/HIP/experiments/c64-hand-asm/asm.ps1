param([string]$Name)
$ErrorActionPreference='Stop';$d='D:\DLSSNR-Lab\hip-backend\c64-hand-asm'
& "$d\asm_compile.exe" "$d\$Name.hsaco" "$d\$Name.s" gfx1201
if($LASTEXITCODE){throw 'assemble failed'}
& "$d\mkset.ps1" -Name $Name -Hsaco "$d\$Name.hsaco"

# Copy the pack8 ALL candidates (CW_PACK8 + W2_PACK8; results/pack8-20260927) to D:\DLSSNR-Lab\pack8-20260927\payload\<arch>.
$ErrorActionPreference='Stop';$e='D:\DLSSNR-Lab\hip-backend\pack8';$root=Split-Path -Parent $MyInvocation.MyCommand.Path
$src=@{gfx1201="$e\modules-ALL";gfx1200="$e\modules-ALL-gfx1200"}
foreach($a in $src.Keys){$dst="$root\payload\$a";New-Item -ItemType Directory -Force $dst|Out-Null
 foreach($m in 'c32-wave1','c64-wave2'){Copy-Item "$($src[$a])\$m.hsaco" "$dst\$m.hsaco" -Force;"$a $m $((Get-FileHash "$dst\$m.hsaco").Hash)"}}

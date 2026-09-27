# Stellar Blade: replace c64-wave2 (both architectures) with set P = production recipe M + W2_PACK8 4 (segmented
# MODE.FP16_OVFL around the C64-C256 fragment packs, no clamp; results/ovfl-census-20260927). Every other module, the add-on
# and the flags stay as installed (set M, deployments/fmed3-20260927). -Restore <backup dir> puts the previous c64-wave2 back.
param([string]$Restore='',[string]$Source='D:\DLSSNR-Lab\hip-backend\pack8\modules-P')
$ErrorActionPreference='Stop'
if(Get-Process SB-Win64-Shipping,LOP-Win64-Shipping,OnimushaWotS,re9 -ErrorAction SilentlyContinue){throw 'a game is running'}
$hip='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets\HIP'
if($Restore){foreach($a in 'gfx1200','gfx1201'){Copy-Item "$Restore\$a\c64-wave2.hsaco" "$hip\$a\" -Force};"restored from $Restore";exit}
$b="D:\DLSSNR-Lab\ovfl-20260927\backups\stellar-$(Get-Date -Format yyyyMMdd-HHmmss)"
foreach($a in 'gfx1200','gfx1201'){
 New-Item -ItemType Directory -Force "$b\$a"|Out-Null;Copy-Item "$hip\$a\c64-wave2.hsaco" "$b\$a\"
 $src="$Source\$a\c64-wave2.hsaco";if(!(Test-Path $src)){throw "missing $src"}
 Copy-Item $src "$hip\$a\c64-wave2.hsaco" -Force;if((Get-FileHash "$hip\$a\c64-wave2.hsaco").Hash -ne (Get-FileHash $src).Hash){throw "copy mismatch $a"}
 "{0} c64-wave2 {1} (was {2})" -f $a,(Get-FileHash "$hip\$a\c64-wave2.hsaco").Hash.Substring(0,12),(Get-FileHash "$b\$a\c64-wave2.hsaco").Hash.Substring(0,12)
}
"backup $b"

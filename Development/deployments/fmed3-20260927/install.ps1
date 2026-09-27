# Stellar Blade: replace both architectures' HIP module sets with the next production recipe (set M: pack8 + SAT3 + FMED3,
# results/fmed3-ovfl-20260927). Add-on and flags untouched. -Restore <backup dir> puts the previous sets back.
param([string]$Restore='',[string]$Source='D:\DLSSNR-Lab\next-modules-20260927\modules')
$ErrorActionPreference='Stop'
if(Get-Process SB-Win64-Shipping,LOP-Win64-Shipping,OnimushaWotS,re9 -ErrorAction SilentlyContinue){throw 'a game is running'}
$hip='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets\HIP'
if($Restore){foreach($a in 'gfx1200','gfx1201'){Copy-Item "$Restore\$a\*.hsaco" "$hip\$a\" -Force};"restored from $Restore";exit}
$b="D:\DLSSNR-Lab\fmed3-20260927\backups\stellar-$(Get-Date -Format yyyyMMdd-HHmmss)"
foreach($a in 'gfx1200','gfx1201'){
 New-Item -ItemType Directory -Force "$b\$a"|Out-Null;Copy-Item "$hip\$a\*.hsaco" "$b\$a\"
 $src=@(Get-ChildItem "$Source\$a" -Filter *.hsaco);if($src.Count -ne 29){throw "expected 29 modules in $Source\$a"}
 foreach($f in $src){Copy-Item $f.FullName "$hip\$a\$($f.Name)" -Force;if((Get-FileHash "$hip\$a\$($f.Name)").Hash -ne (Get-FileHash $f.FullName).Hash){throw "copy mismatch $($f.Name)"}}
}
"installed 2x29 modules; backup $b"
foreach($m in 'c32-wave1','c64-wave2','c512-m32-mh'){"gfx1201 {0,-12} {1}" -f $m,(Get-FileHash "$hip\gfx1201\$m.hsaco").Hash.Substring(0,12)}

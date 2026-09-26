param([string]$RestoreBackup='')
# Replace c32-wave1 + c64-wave2 (gfx1200/gfx1201) with the pack8 build (CW_PACK8 + W2_PACK8; bit-exact, network 900 -8.7%,
# 1080 -9.1%; results/pack8-20260927). No flag or add-on change (both modules load under DLSS5_HIP_WAVE_OWNED=1).
# Run from D:\DLSSNR-Lab\pack8-20260927 (this script + payload\) with Stellar Blade closed. -RestoreBackup <dir> undoes it.
$ErrorActionPreference='Stop'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
$root=Split-Path -Parent $MyInvocation.MyCommand.Path;$hip="$g\DLSS5-AMD\native-game-tiled-assets\HIP"
$old=@{'gfx1200/c32-wave1'='128BB82C0EF8847F561A21975D0846E4B6859FC34AB464266BAAD65BC494D8C4';'gfx1200/c64-wave2'='58F948F3DDED75C86161FB4624EF3A038F5E77E8638347727DB659542F2F7081'
 'gfx1201/c32-wave1'='7AC34418CD3DD9FBCDF3E5D534CFEEE610AF21966DD84D05D7CAB308FF4330D1';'gfx1201/c64-wave2'='8F03E233F638325B869CFB46E965E933242C893367F7FBEBCF187862EC3CDA91'}
$new=@{'gfx1200/c32-wave1'='960B2811DFA06E220CDFD7921D7C5859E007F4BE2043E76170030EF96C05F730';'gfx1200/c64-wave2'='2FA28645BE3F6457814FB69F2D97BD7EE702149F21F0BDA5D49C67F81B2EC1AE'
 'gfx1201/c32-wave1'='686B92FCA33CC59A946175E624F3B610CF6DF6E7B53868ABA07810898FA0FEEA';'gfx1201/c64-wave2'='FAA330FDBCF808319AF0ECC1680A8C9542CFED0B960F901EE87B969CC85AB1A6'}
if(Get-Process SB-Win64-Shipping -ErrorAction SilentlyContinue){throw 'Stellar Blade running; no module replacement allowed'}
function P($k){"$hip\$($k.Replace('/','\')).hsaco"}
if($RestoreBackup){foreach($k in $old.Keys){Copy-Item "$RestoreBackup\$($k.Replace('/','\')).hsaco" (P $k) -Force;if((Get-FileHash (P $k)).Hash -ne $old[$k]){throw "restore verify $k"}};"RESTORED $RestoreBackup";exit}
foreach($k in $old.Keys){if((Get-FileHash (P $k)).Hash -ne $old[$k]){throw "installed $k is not the 0.32 module"};if((Get-FileHash "$root\payload\$($k.Replace('/','\')).hsaco").Hash -ne $new[$k]){throw "payload hash $k"}}
$b="$root\backups\stellar-$(Get-Date -Format yyyyMMdd-HHmmss)"
foreach($k in $old.Keys){$t="$b\$($k.Replace('/','\')).hsaco";New-Item -ItemType Directory -Force (Split-Path $t)|Out-Null;Copy-Item (P $k) $t}
try{foreach($k in $new.Keys){Copy-Item "$root\payload\$($k.Replace('/','\')).hsaco" (P $k) -Force;if((Get-FileHash (P $k)).Hash -ne $new[$k]){throw "install verify $k"}}}
catch{foreach($k in $old.Keys){Copy-Item "$b\$($k.Replace('/','\')).hsaco" (P $k) -Force};throw}
"INSTALLED pack8 c32-wave1 + c64-wave2 gfx1200/gfx1201; BACKUP=$b"

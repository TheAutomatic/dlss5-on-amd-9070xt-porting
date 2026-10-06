param([switch]$PinIdle)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\c128-c64-inchain-20261001';$s='D:\DLSSNR-Lab\hip-backend\input-slim-20261001'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall'}){throw 'game running'}
New-Item -ItemType Directory -Force "$root\flat-A"|Out-Null
$files=@(Get-ChildItem "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201" -Filter '*.hsaco');if($files.Count -ne 31){throw 'Expected 31'}
Copy-Item ($files|ForEach-Object FullName) "$root\flat-A" -Force
"c64-wave2 installed $((Get-FileHash "$root\flat-A\c64-wave2.hsaco").Hash)"
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1'){(Get-Content "$s\$f" -Raw).Replace('input-slim-20261001\assets-base','KEEPASSETS').Replace('input-slim-20261001','c128-c64-inchain-20261001').Replace('KEEPASSETS','input-slim-20261001\assets-base')|Set-Content "$root\$f"}
# 2026-10-01 AE ledger: bit-exact runs pin the ViT adaptive idle reset (host DLSS5_VIT_ADAPTIVE_IDLE_MS; the benchmark clears DLSS5_* env and
# reads only the flags file, so it goes into every run's flags). Only with -PinIdle, and only when BOTH base and candidate hosts have
# the knob: an old host keeps the 500 ms reset, which always fires after the ~1 s first frame, so a one-sided pin changes motion output.
if($PinIdle){$t=Get-Content "$root\regression.ps1" -Raw;$t=$t.Replace("`$flags += @('DLSS5_HIP_SWIN_RUN=1',","`$flags += @('DLSS5_VIT_ADAPTIVE_IDLE_MS=1000000000','DLSS5_HIP_SWIN_RUN=1',");if($t -notmatch 'ADAPTIVE_IDLE_MS'){throw 'idle pin not injected'};Set-Content "$root\regression.ps1" $t}
'SETUP_DONE'

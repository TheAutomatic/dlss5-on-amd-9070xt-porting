# bitexact-pm-20261001: flat-A = installed Stellar modules (31), regression harness from input-slim (assets-base/assets-cand kept there), idle pinned.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\bitexact-pm-20261001';$s='D:\DLSSNR-Lab\hip-backend\input-slim-20261001'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^LOP-Win'}){throw 'game running'}
New-Item -ItemType Directory -Force "$root\flat-A"|Out-Null
$files=@(Get-ChildItem "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201" -Filter '*.hsaco');if($files.Count -ne 31){throw 'Expected 31'}
Copy-Item ($files|ForEach-Object FullName) "$root\flat-A" -Force
Get-ChildItem "$root\flat-A" | Get-FileHash | ForEach-Object{"$($_.Hash.Substring(0,8)) $(Split-Path -Leaf $_.Path)"} | Set-Content "$root\installed.txt"
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash)" | Add-Content "$root\installed.txt"
"decode-shader $((Get-FileHash "$game\DLSS5-AMD\native-game-tiled-assets\native_codec_decode.hlsl").Hash)" | Add-Content "$root\installed.txt"
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1'){(Get-Content "$s\$f" -Raw).Replace('input-slim-20261001','bitexact-pm-20261001')|Set-Content "$root\$f"}
$t=Get-Content "$root\regression.ps1" -Raw;$t=$t.Replace("`$flags += @('DLSS5_HIP_SWIN_RUN=1',","`$flags += @('DLSS5_VIT_ADAPTIVE_IDLE_MS=1000000000','DLSS5_HIP_SWIN_RUN=1',").Replace('|^rtc_compile','');if($t -notmatch 'ADAPTIVE_IDLE_MS'){throw 'idle pin not injected'};Set-Content "$root\regression.ps1" $t
if(Test-Path "$root\src.zip"){Remove-Item "$root\src" -Recurse -Force -EA 0;Expand-Archive "$root\src.zip" "$root\src" -Force;Remove-Item "$root\src.zip"}
Get-Content "$root\installed.txt"
'SETUP_DONE'

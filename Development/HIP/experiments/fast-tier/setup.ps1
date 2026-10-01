$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\fast-tier-20261001';$s='D:\DLSSNR-Lab\hip-backend\c128-c64-inchain-20261001'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall'}){throw 'game running'}
New-Item -ItemType Directory -Force "$root\flat-A"|Out-Null
$files=@(Get-ChildItem "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201" -Filter '*.hsaco');if($files.Count -ne 31){throw 'Expected 31'}
Copy-Item ($files|ForEach-Object FullName) "$root\flat-A" -Force
Get-ChildItem "$root\flat-A" | Get-FileHash | ForEach-Object{"$($_.Hash.Substring(0,8)) $(Split-Path -Leaf $_.Path)"} | Set-Content "$root\installed.txt"
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash)" | Add-Content "$root\installed.txt"
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1'){(Get-Content "$s\$f" -Raw).Replace('c128-c64-inchain-20261001','fast-tier-20261001')|Set-Content "$root\$f"}
$t=Get-Content "$root\regression.ps1" -Raw;if($t -notmatch 'ADAPTIVE_IDLE_MS=1000000000'){throw 'no idle pin'}
$t=$t.Replace('|^rtc_compile','').Replace('if($different){throw "Output changed $t ($different/12)"};"SAME $b $t"','"CMP $b $t diff=$different/12"')
Set-Content "$root\regression.ps1" $t
Get-Content "$root\installed.txt"|Select-String 'vit-stream|c32-wave1|deep_fast-packed|addon'
'SETUP_DONE'

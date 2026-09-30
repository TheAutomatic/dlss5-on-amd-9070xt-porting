# c512-qkv-pipeline: base flat-G (Stellar installed now), cand flat-G + build-<B> c512-m32-mh; host P6; 19 bit-exact + N ABBA. Under gpu.lock.
param([string]$B,[int]$Rounds=3,[switch]$SkipTiming)
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001';$me="c512-qkv-pipeline $B";$L='D:\DLSSNR-Lab\gpu.lock'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
$t0=Get-Date
while(Test-Path $L){ if(((Get-Date)-(Get-Item $L).LastWriteTime).TotalMinutes -gt 40){Remove-Item $L -Force;"stale lock removed";break}
 if(((Get-Date)-$t0).TotalMinutes -gt 30){"LOCK TIMEOUT: $(Get-Content $L)";exit 1}; Start-Sleep 60}
if(Get-Process|?{$_.ProcessName -match 'Shipping|^re9$|^Onimusha'}){"GAME RUNNING";exit 1}
"$me $(Get-Date -Format s)"|Out-File -Encoding ascii $L
$j=Start-Job -ScriptBlock {param($L,$me) while($true){Start-Sleep 300; if(Test-Path $L){"$me $(Get-Date -Format s) (refresh)"|Out-File -Encoding ascii $L}}} -ArgumentList $L,$me
try{
 Remove-Item -Recurse -Force "$root\flat-G","$root\flat-$B","$root\runtime-regression-$B-*" -EA 0
 New-Item -ItemType Directory -Force "$root\flat-G","$root\flat-$B"|Out-Null
 Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\flat-G";Copy-Item "$root\flat-G\*" "$root\flat-$B"
 Copy-Item "D:\DLSSNR-Lab\hip-backend\c512-qkv-pipeline-20261001\build-$B\gfx1201\c512-m32-mh.hsaco" "$root\flat-$B" -Force
 "installed addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash.Substring(0,8)) mh $((Get-FileHash "$root\flat-G\c512-m32-mh.hsaco").Hash.Substring(0,8)) deep $((Get-FileHash "$root\flat-G\c512-m32-deep.hsaco").Hash.Substring(0,8)) cand $((Get-FileHash "$root\flat-$B\c512-m32-mh.hsaco").Hash.Substring(0,8))"
 & "$root\full.ps1" -BaseSet G -BaseBench benchmark-P6.exe -Set $B -Cand P6 -RollHost P6 -Rounds $Rounds -SkipTiming:$SkipTiming *> "$root\full-$B.log"
 "SAME count $((Select-String "$root\full-$B.log" -Pattern '^SAME|AE CSV SAME').Count)"
 Select-String "$root\full-$B.log" -Pattern 'DIFF|FAIL|throw' | select -First 5 | %{$_.Line}
 & "$root\summarize.ps1" -Sets $B
} finally { Stop-Job $j; Remove-Job $j -Force; if((Test-Path $L) -and ((Get-Content $L) -match 'c512-qkv-pipeline')){Remove-Item $L -Force}; "LOCK DROPPED" }

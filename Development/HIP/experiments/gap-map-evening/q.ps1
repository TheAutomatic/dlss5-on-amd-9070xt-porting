# gap-map-evening: q.ps1 -Name X -Mods 'module=build,...' [-Rounds 3] [-SkipTiming] [-SkipCorrect]; base = flat-G (Stellar gfx1201 as installed) on benchmark-E; cand = flat-G + overrides on benchmark-E. Under gpu.lock.
param([string]$Name,[string]$Mods,[string]$Host_='E',[string]$BaseHost='E',[int]$Rounds=3,[switch]$SkipTiming,[switch]$SkipCorrect)
$root='D:\DLSSNR-Lab\hip-backend\gap-map-evening-20261001';$me="gap-map-evening $Name";$L='D:\DLSSNR-Lab\gpu.lock'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
$t0=Get-Date
while(Test-Path $L){ if(((Get-Date)-(Get-Item $L).LastWriteTime).TotalMinutes -gt 40){Remove-Item $L -Force;"stale lock removed";break}
 if(((Get-Date)-$t0).TotalMinutes -gt 30){"LOCK TIMEOUT: $(Get-Content $L)";exit 1}; Start-Sleep 60}
if(Get-Process|?{$_.ProcessName -match 'Shipping|^re9$|^Onimusha'}){"GAME RUNNING";exit 1}
"$me $(Get-Date -Format s)"|Out-File -Encoding ascii $L
$j=Start-Job -ScriptBlock {param($L,$me) while($true){Start-Sleep 300; if(Test-Path $L){"$me $(Get-Date -Format s) (refresh)"|Out-File -Encoding ascii $L}}} -ArgumentList $L,$me
try{
 Remove-Item -Recurse -Force "$root\flat-G","$root\flat-$Name","$root\runtime-regression-$Name-*" -EA 0
 New-Item -ItemType Directory -Force "$root\flat-G","$root\flat-$Name"|Out-Null
 Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\flat-G";Copy-Item "$root\flat-G\*" "$root\flat-$Name"
 "installed addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash.Substring(0,8)) mhpw $((Get-FileHash "$root\flat-G\multihead-fast-padded-wave-packed.hsaco").Hash.Substring(0,8))"
 foreach($m in ($Mods -split ','|?{$_})){$mod,$b=$m -split '=';Copy-Item "$root\build-$b\gfx1201\$mod.hsaco" "$root\flat-$Name" -Force;"cand $mod <- $b $((Get-FileHash "$root\flat-$Name\$mod.hsaco").Hash.Substring(0,8))"}
 & "$root\full.ps1" -BaseSet G -BaseBench "benchmark-$BaseHost.exe" -Set $Name -Cand $Host_ -RollHost $Host_ -Rounds $Rounds -SkipTiming:$SkipTiming -SkipCorrect:$SkipCorrect *> "$root\full-$Name.log"
 "SAME count $((Select-String "$root\full-$Name.log" -Pattern '^SAME|AE CSV SAME').Count)"
 Select-String "$root\full-$Name.log" -Pattern 'DIFF|FAIL|Exception|failed' | select -First 5 | %{$_.Line}
 & "$root\summarize.ps1" -Sets $Name
 & "$root\p99m.ps1" -Set $Name
} finally { Stop-Job $j; Remove-Job $j -Force; if((Test-Path $L) -and ((Get-Content $L) -match 'gap-map-evening')){Remove-Item $L -Force}; "LOCK DROPPED" }

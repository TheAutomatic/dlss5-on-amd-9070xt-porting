# compiler-sweep final: flat-CS = flat-A (installed) + recipe-on c32-wave1 / c512-m32-deep (gfx1201); 19 groups (-PinIdle) + 3 ABBA rounds.
# Runs inside the c128-c64-inchain root (same hosts/regression scripts). Lock taken by gpulock wrapper (guard.sh aborts on games).
param([string]$Set='CS',[string]$Mods='c32-wave1,c512-m32-deep')
$root='D:\DLSSNR-Lab\hip-backend\c128-c64-inchain-20261001';$src='D:\DLSSNR-Lab\hip-backend\compiler-sweep-20261001\recipe-on\gfx1201';$L='D:\DLSSNR-Lab\gpu.lock'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
"compiler-sweep $Set $(Get-Date -Format s)"|Out-File -Encoding ascii $L
try{
& "$root\setup.ps1" -PinIdle
$t=Get-Content "$root\regression.ps1" -Raw;$t=$t.Replace('|^rtc_compile','');Set-Content "$root\regression.ps1" $t
Get-ChildItem $root -Directory -Filter 'runtime-regression-*'|Remove-Item -Recurse -Force
Remove-Item -Recurse -Force "$root\flat-$Set" -EA 0;New-Item -ItemType Directory -Force "$root\flat-$Set"|Out-Null;Copy-Item "$root\flat-A\*.hsaco" "$root\flat-$Set" -Force
foreach($m in $Mods -split ','){Copy-Item "$src\$m.hsaco" "$root\flat-$Set" -Force;"$m $((Get-FileHash "$root\flat-$Set\$m.hsaco").Hash.Substring(0,8)) base $((Get-FileHash "$root\flat-A\$m.hsaco").Hash.Substring(0,8))"}
try{& "$root\full.ps1" -Set $Set -Rounds 3 *> "$root\full-$Set.log";'FULL OK'}catch{"FULL FAIL $_"}
"SAME-count: $((Select-String -Path "$root\full-$Set.log" -Pattern '^SAME|AE CSV SAME').Count)"
Get-Content "$root\full-$Set.log" | Select-String 'FAIL|changed|throw|Error|DIFF' | Select-Object -Last 10
& "$root\summarize.ps1" -Sets $Set;& "$root\p99m.ps1" -Set $Set
} finally {
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force
if((Test-Path $L) -and ((Get-Content $L) -match 'compiler-sweep')){Remove-Item $L -Force}; 'LOCK DROPPED'}

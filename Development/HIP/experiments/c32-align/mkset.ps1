# mkset -Name X -From flat-Y -C32 <build dir name or ''> -Mh <build dir name or ''>
param([string]$Name,[string]$From='A',[string]$C32='',[string]$Mh='')
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\c32-align-20260930'
New-Item -ItemType Directory -Force "$root\flat-$Name"|Out-Null;Copy-Item "$root\flat-$From\*.hsaco" "$root\flat-$Name" -Force
if($C32){Copy-Item (Get-ChildItem "$root\build-$C32\gfx1201" -Recurse -Filter 'c32-wave1.hsaco'|Select-Object -First 1).FullName "$root\flat-$Name" -Force}
if($Mh){Copy-Item (Get-ChildItem "$root\build-$Mh\gfx1201" -Recurse -Filter 'multihead-fast-padded-wave-packed.hsaco'|Select-Object -First 1).FullName "$root\flat-$Name" -Force}
Get-ChildItem "$root\flat-$Name" -Filter '*.hsaco'|Where-Object{$_.Name -match 'c32-wave1|multihead-fast-padded-wave-packed'}|ForEach-Object{"$($_.Name) $((Get-FileHash $_.FullName).Hash)"}

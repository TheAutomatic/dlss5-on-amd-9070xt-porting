# flat-<Set> = flat-A + listed build dirs' modules ("build:module")
param([string]$Set,[string[]]$From=@())
$root='D:\DLSSNR-Lab\hip-backend\fast-tier-20261001'
Remove-Item "$root\flat-$Set" -Recurse -Force -EA 0;New-Item -ItemType Directory -Force "$root\flat-$Set"|Out-Null;Copy-Item "$root\flat-A\*.hsaco" "$root\flat-$Set" -Force
foreach($x in @($From|ForEach-Object{$_ -split ","}|Where-Object{$_})){$b,$m=$x.Split(':');Copy-Item "$root\build-$b\gfx1201\$m.hsaco" "$root\flat-$Set" -Force;"flat-$Set <- $b $m"}

# bisect.ps1: host-only ABBA (timing, 3 rounds) of each intermediate host commit vs installed host (base); modules = flat-A (installed) both sides
param([string[]]$Hosts)
$root='D:\DLSSNR-Lab\hip-backend\rebuild-baseline-20261001'
$Hosts=@($Hosts|%{$_ -split ','}|?{$_})
foreach($h in $Hosts){$s="X$h";Remove-Item "$root\flat-$s" -Recurse -Force -EA 0;New-Item -ItemType Directory "$root\flat-$s"|Out-Null;Copy-Item "$root\flat-A\*.hsaco" "$root\flat-$s";Get-ChildItem $root -Directory -Filter "runtime-regression-$s-*"|Remove-Item -Recurse -Force
 & "$root\full.ps1" -Set $s -Rounds 3 -SkipCorrect -CandHost $h *> "$root\full-$s.log";& "$root\summarize.ps1" -Sets $s;& "$root\p99m.ps1" -Set $s}
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force
'BISECT_DONE'

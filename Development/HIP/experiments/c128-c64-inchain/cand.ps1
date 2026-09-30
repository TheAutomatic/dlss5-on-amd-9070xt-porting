# one candidate: build <Module> with <Defs> (gfx1201), flat-<Set> = flat-A + it, 19 groups + 3 ABBA rounds
param([string]$Set,[string]$Module,[string[]]$Defs)
$root='D:\DLSSNR-Lab\hip-backend\c128-c64-inchain-20261001'
& "$root\setup.ps1"
$t=Get-Content "$root\regression.ps1" -Raw;$t=$t.Replace('|^rtc_compile','');Set-Content "$root\regression.ps1" $t
Get-ChildItem $root -Directory -Filter 'runtime-regression-*'|Remove-Item -Recurse -Force
& "$root\build.ps1" -Name "prod-$Set" -Module $Module
& "$root\build.ps1" -Name $Set -Module $Module -Defs $Defs
New-Item -ItemType Directory -Force "$root\flat-$Set"|Out-Null;Copy-Item "$root\flat-A\*.hsaco" "$root\flat-$Set" -Force;Copy-Item "$root\build-$Set\gfx1201\$Module.hsaco" "$root\flat-$Set" -Force
try{& "$root\full.ps1" -Set $Set -Rounds 3 *> "$root\full-$Set.log";'FULL OK'}catch{"FULL FAIL $_"}
Get-Content "$root\full-$Set.log" | Select-String 'SAME|FAIL|changed|DONE|throw|Error' | Select-Object -Last 30
& "$root\summarize.ps1" -Sets $Set;& "$root\p99m.ps1" -Set $Set
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force

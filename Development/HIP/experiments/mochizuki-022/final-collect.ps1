$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mochizuki-022'
if(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match '^benchmark|^ledger$|^rt_bench'}){throw 'Benchmark still running'}
& "$r\collect.ps1"
& "$r\collect-adaptive.ps1"
& "$r\trace-tchain.ps1"
$rows=@(foreach($batch in 'correct','adaptive','r1','r2'){foreach($d in Get-ChildItem "$r\runtime-regression-H-$batch" -Directory){
 [pscustomobject]@{batch=$batch;case=$d.Name;trace=((Get-Content "$($d.FullName)\run.log"|Where-Object {$_ -like 'WG4 *'}) -join ';')}
}})
$rows|Export-Csv "$r\group4-traces.csv" -NoTypeInformation
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets\HIP'
$ids=@(foreach($a in 'gfx1200','gfx1201'){foreach($f in Get-ChildItem "$r\modules-A\$a" -Filter '*.hsaco'){
 $b=(Get-FileHash $f.FullName).Hash;$v=(Get-FileHash "$g\$a\$($f.Name)").Hash
 [pscustomobject]@{arch=$a;module=$f.Name;baseline=$b;installed=$v;same=($b -eq $v)}
}})
$ids|ConvertTo-Json|Set-Content "$r\installed-identity.json"
if(@($ids|Where-Object {!$_.same}).Count){throw 'Installed module changed externally'}
'FINAL_COLLECT_DONE'

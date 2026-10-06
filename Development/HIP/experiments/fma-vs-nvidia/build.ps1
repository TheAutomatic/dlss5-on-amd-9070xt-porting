$ErrorActionPreference='Stop'
$r='D:\DLSSNR-Lab\hip-backend\fma-vs-nvidia'
function Idle {if(Get-Process | Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark$'}){throw 'GPU busy'}}
Idle
# Current installed ACO-lineup modules, not its older experimental baseline.
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets\HIP'
Get-ChildItem $game -Recurse -Filter '*.hsaco' | ForEach-Object { [pscustomobject]@{path=$_.FullName;sha=(Get-FileHash $_.FullName).Hash} } | ConvertTo-Json | Set-Content "$r\installed-before.json"
New-Item -ItemType Directory -Force "$r\flat-A" | Out-Null
Copy-Item "$game\gfx1201\*.hsaco" "$r\flat-A" -Force
Copy-Item 'D:\DLSSNR-Lab\hip-backend\aco-lineup\benchmark.exe' "$r\benchmark.exe" -Force
foreach($set in 'Z','F','H'){
 foreach($m in 'c32-wave1','c64-wave2'){
  Idle
  & "$r\hip-$set\build-modules.ps1" -SourceDir "$r\hip-$set" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-$set-$m" -Only $m -Targets gfx1201
  if($LASTEXITCODE){throw "compile $set $m"}
 }
 New-Item -ItemType Directory -Force "$r\flat-$set" | Out-Null
 Copy-Item "$r\flat-A\*.hsaco" "$r\flat-$set" -Force
 foreach($m in 'c32-wave1','c64-wave2'){Copy-Item "$r\build-$set-$m\$m.hsaco" "$r\flat-$set\$m.hsaco" -Force}
}

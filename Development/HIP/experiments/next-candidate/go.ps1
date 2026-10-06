# go.ps1: N = HEAD host + full main recipe (62, flat-N gfx1201) vs A = 0.39 installed; 19 groups (idle pinned) + 3 ABBA; then whole-net wall.
$root='D:\DLSSNR-Lab\hip-backend\next-candidate-20261002';$L='D:\DLSSNR-Lab\gpu.lock'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
"next-candidate $(Get-Date -Format s)"|Out-File -Encoding ascii $L
try{
Get-ChildItem $root -Directory -Filter "runtime-regression-N-*"|Remove-Item -Recurse -Force
try{& "$root\full.ps1" -Set N -Rounds 3 -CandHost N -RollHost Nroll *> "$root\full-N.log";'FULL OK'}catch{"FULL FAIL $_"}
"SAME-count: $((Select-String -Path "$root\full-N.log" -Pattern '^SAME|AE CSV SAME').Count)"
Get-Content "$root\full-N.log" | Select-String 'FAIL|changed|throw|Error|DIFF' | Select-Object -Last 10
& "$root\summarize.ps1" -Sets N;& "$root\p99m.ps1" -Set N
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force
& "$root\wall.ps1"
} finally { Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression|\\wall\\'} | Remove-Item -Force -EA 0; if((Test-Path $L) -and ((Get-Content $L) -match 'next-candidate')){Remove-Item $L -Force}; 'LOCK DROPPED' }
'GO_DONE'

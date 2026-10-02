# go.ps1 (free-res): lock + game check; F = free-res host with DLSS5_NETWORK_FREE_RES unset (default 0) vs base: 19 groups + 3 ABBA; then rt.ps1.
param([switch]$SkipF,[switch]$SkipRt)
$root='D:\DLSSNR-Lab\hip-backend\free-res-20261002';$L='D:\DLSSNR-Lab\gpu.lock'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"free-res $(Get-Date -Format s)"|Out-File -Encoding ascii $L
try{
 if(!$SkipF){$n='F';Get-ChildItem $root -Directory -Filter "runtime-regression-$n-*"|Remove-Item -Recurse -Force
  try{& "$root\full.ps1" -Set $n -Rounds 3 -CandAssets -CandHost F -RollHost Froll *> "$root\full-$n.log";"FULL $n OK"}catch{"FULL $n FAIL $_"}
  "SAME-count $n`: $((Select-String -Path "$root\full-$n.log" -Pattern '^SAME|AE CSV SAME').Count)"
  Get-Content "$root\full-$n.log" | Select-String 'FAIL|changed|throw|Error|DIFF' | Select-Object -Last 10
  & "$root\summarize.ps1" -Sets $n;& "$root\p99m.ps1" -Set $n
  Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force}
 if(!$SkipRt){try{& "$root\rt.ps1"}catch{"RT FAIL $_"}}
} finally { Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force -EA 0; if((Test-Path $L) -and ((Get-Content $L) -match 'free-res')){Remove-Item $L -Force}; 'LOCK DROPPED' }
'GO_DONE'

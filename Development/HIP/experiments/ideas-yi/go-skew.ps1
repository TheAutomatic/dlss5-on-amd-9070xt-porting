# go-skew.ps1 (ideas-yi direction 2): allocation-offset scan. Each config "name:stride:mod:seed:kind" = one ABBA round
# (base = benchmark-base + flat-A, candidate = benchmark-K (HIP_ADDR_SKEW 1) + flat-K (= flat-A) with the env offsets).
param([string[]]$Configs,[int]$Rounds=1,[switch]$Correct)
$root='D:\DLSSNR-Lab\hip-backend\ideas-yi-20261002';$L='D:\DLSSNR-Lab\gpu.lock'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"ideas-yi $(Get-Date -Format s)"|Out-File -Encoding ascii $L
try{if(!(Test-Path "$root\flat-K")){Copy-Item "$root\flat-A" "$root\flat-K" -Recurse}
 Copy-Item "$root\benchmark-K.exe" "$root\benchmark-Kroll.exe" -Force
 foreach($c in @($Configs|%{$_ -split ","}|?{$_})){$p=$c -split ':';$n=$p[0]
  $env:DLSS5_HIP_ADDR_SKEW_STRIDE=$p[1];$env:DLSS5_HIP_ADDR_SKEW_MOD=$p[2];$env:DLSS5_HIP_ADDR_SKEW_SEED=$p[3];$env:DLSS5_HIP_ADDR_SKEW_KIND=$p[4]
  "== $c $(Get-Date -Format T)"
  # flat-<n> as a junction-free copy name so the result dirs are per config
  if(!(Test-Path "$root\flat-$n")){Copy-Item "$root\flat-A" "$root\flat-$n" -Recurse}
  Get-ChildItem $root -Directory -Filter "runtime-regression-$n-*"|Remove-Item -Recurse -Force
  try{& "$root\full.ps1" -Set $n -Rounds $Rounds -CandHost K -RollHost Kroll -SkipCorrect:(!$Correct) *> "$root\full-$n.log";"FULL $n OK"}catch{"FULL $n FAIL $_"}
  if($Correct){"SAME-count $n`: $((Select-String -Path "$root\full-$n.log" -Pattern '^SAME|AE CSV SAME').Count)"}
  & "$root\summarize.ps1" -Sets $n;& "$root\p99m.ps1" -Set $n}
} catch {"GO FAIL $_"} finally {Remove-Item Env:DLSS5_HIP_ADDR_SKEW_* -EA 0; Get-ChildItem $root -Recurse -Include *.f16,*.ppm -EA 0|?{$_.FullName -match 'runtime-regression'}|Remove-Item -Force -EA 0; if((Test-Path $L) -and ((Get-Content $L) -match 'ideas-yi')){Remove-Item $L -Force}; 'LOCK DROPPED' }
'GO_DONE'

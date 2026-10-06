# go.ps1 (fast-numeric): GPU lock + game check, then phases. D = option unset (full.ps1: 19 SAME + ABBA, flat-F so the -fast files sit in the
# directory); N = DLSS5_FAST_NUMERIC=1 (7 cases x 12 frames PSNR vs base + ABBA); ALL = fast mode fully on (FAST_NUMERIC=1, 1088 rows, AE on,
# motion sequence; release block skip is on both sides) ABBA; NA = FAST_NUMERIC=1 + 1088 rows, AE off, default sequence (full compute, for the mochizuki comparison). Base = benchmark-base + flat-A + default flags.
param([string[]]$Phases=@('D','N','ALL'),[int]$Rounds=3)
$root='D:\DLSSNR-Lab\hip-backend\fast-numeric-20261003';$L='D:\DLSSNR-Lab\gpu.lock'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"fast-numeric $(Get-Date -Format s)"|Out-File -Encoding ascii $L
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
$fn='DLSS5_FAST_NUMERIC=1';$all=@($fn,'DLSS5_NETWORK_1080_ROWS=1088','DLSS5_VIT_ADAPTIVE=1','DLSS5_VIT_REUSE_PERIOD=4')
try{$Phases=@($Phases|%{$_ -split ","}|?{$_})
 foreach($ph in $Phases){"== $ph $(Get-Date -Format T)"
  Get-ChildItem $root -Directory -Filter "runtime-regression-$ph-*"|Remove-Item -Recurse -Force
  if($true){Remove-Item "$root\flat-$ph" -Recurse -Force -EA 0;Copy-Item "$root\flat-F" "$root\flat-$ph" -Recurse}
  if($ph -eq 'D'){try{& "$root\full.ps1" -Set D -Rounds $Rounds -CandHost F -RollHost Froll *> "$root\full-D.log";"FULL D OK"}catch{"FULL D FAIL $_"}
   "SAME-count D: $((Select-String -Path "$root\full-D.log" -Pattern '^SAME|AE CSV SAME').Count)"
   Get-Content "$root\full-D.log"|Select-String 'FAIL|changed|throw|Error|DIFF'|Select-Object -Last 5}
  if($ph -eq 'N'){& "$root\regression-cmp.ps1" -Set N -Adaptive 0 -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-F.exe -CandidateExtra $fn -CorrectnessOnly -Batch q0 *> "$root\cmp-N.log"
   Select-String -Path "$root\cmp-N.log" -Pattern '^CMP';& "$root\psnr.ps1" -Dir "$root\runtime-regression-N-q0"|Tee-Object "$root\psnr-N.txt"
   foreach($r in 1..$Rounds){& "$root\regression.ps1" -Set N -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-F.exe -CandidateExtra $fn -TimingOnly -TimingFrames 1000 -Batch "timing-$r" *> "$root\timing-N-$r.log"}}
  if($ph -eq 'ALL'){foreach($r in 1..$Rounds){& "$root\regression.ps1" -Set ALL -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-F.exe -CandidateExtra $all -TimingOnly -TimingSequence 1 -TimingFrames 1000 -Batch "timing-$r" *> "$root\timing-ALL-$r.log"}}
  if($ph -eq 'NA'){foreach($r in 1..$Rounds){& "$root\regression.ps1" -Set NA -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-F.exe -CandidateExtra @($fn,'DLSS5_NETWORK_1080_ROWS=1088') -TimingOnly -TimingFrames 1000 -Batch "timing-$r" *> "$root\timing-NA-$r.log"}}
  & "$root\summarize.ps1" -Sets $ph|Tee-Object "$root\abba-$ph.txt";& "$root\p99m.ps1" -Set $ph|Tee-Object -Append "$root\abba-$ph.txt"
  Get-ChildItem $root -Recurse -Include *.f16,*.ppm -EA 0|?{$_.FullName -match 'runtime-regression'}|Remove-Item -Force -EA 0}
} catch {"GO FAIL $_"} finally { Get-ChildItem $root -Recurse -Include *.f16,*.ppm -EA 0|?{$_.FullName -match 'runtime-regression'}|Remove-Item -Force -EA 0; if((Test-Path $L) -and ((Get-Content $L) -match 'fast-numeric')){Remove-Item $L -Force}; 'LOCK DROPPED' }
'GO_DONE'

# go.ps1 (fast-vit-c512): GPU lock + game check, then phases.
# HOST = host-patch neutrality (F2 vs base exe, both flat-A, 19 SAME + 1 ABBA round);
# P1 = ViT attention fast (deep_fast-packed VIT_FAST_NUM 3 in prod name, FAST_NUMERIC off);
# P2 = ViT contract+projection fast (vit-stream VIT_FAST_NUM 4, FAST_NUMERIC off);
# P3 = C512 f16-residual projection (deep_fast VIT_FAST_NUM 24 + mh_fast C512_FAST_PROJ 1, host F2, FAST_NUMERIC=1);
# PF = full fast default (all five -fast twins, host F2, FAST_NUMERIC=1).
param([string[]]$Phases=@('HOST','P1','P2','P3'),[int]$Rounds=3)
$root='D:\DLSSNR-Lab\hip-backend\fast-vit-20261003';$L='D:\DLSSNR-Lab\gpu.lock'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"fast-vit $(Get-Date -Format s)"|Out-File -Encoding ascii $L
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
try{$Phases=@($Phases|%{$_ -split ","}|?{$_})
 foreach($ph in $Phases){"== $ph $(Get-Date -Format T)"
  Get-ChildItem $root -Directory -Filter "runtime-regression-$ph-*"|Remove-Item -Recurse -Force
  if($ph -eq 'HOST'){& "$root\full.ps1" -Set S -Rounds 1 -CandHost F2 -RollHost F2roll *> "$root\full-S.log"
   "SAME-count: $((Select-String -Path "$root\full-S.log" -Pattern '^SAME|AE CSV SAME').Count)"
   Get-Content "$root\full-S.log"|Select-String 'FAIL|changed|throw|Error'|Select-Object -Last 5}
  if($ph -eq 'P1' -or $ph -eq 'P2'){
   & "$root\regression-cmp.ps1" -Set $ph -Adaptive 0 -BenchName benchmark-base2.exe -Base A -CandidateBenchName benchmark-base2.exe -CorrectnessOnly -Batch q0 *> "$root\cmp-$ph.log"
   Select-String -Path "$root\cmp-$ph.log" -Pattern '^CMP'
   & "$root\psnr.ps1" -Dir "$root\runtime-regression-$ph-q0"|Tee-Object "$root\psnr-$ph.txt"
   foreach($r in 1..$Rounds){& "$root\regression.ps1" -Set $ph -BenchName benchmark-base2.exe -Base A -CandidateBenchName benchmark-base2.exe -TimingOnly -TimingFrames 1000 -Batch "timing-$r" *> "$root\timing-$ph-$r.log"}}
  if($ph -eq 'FB'){$fn='DLSS5_FAST_NUMERIC=1'
   & "$root\regression-cmp.ps1" -Set A -Adaptive 0 -BenchName benchmark-base2.exe -Base A -CandidateBenchName benchmark-F2.exe -CandidateExtra $fn -CorrectnessOnly -Batch q0 *> "$root\cmp-FB.log"
   Select-String -Path "$root\cmp-FB.log" -Pattern '^CMP'
   'FB Done'}
  if($ph -eq 'P3' -or $ph -eq 'PF'){$fn='DLSS5_FAST_NUMERIC=1'
   & "$root\regression-cmp.ps1" -Set $ph -Adaptive 0 -BenchName benchmark-base2.exe -Base A -CandidateBenchName benchmark-F2.exe -CandidateExtra $fn -CorrectnessOnly -Batch q0 *> "$root\cmp-$ph.log"
   Select-String -Path "$root\cmp-$ph.log" -Pattern '^CMP|missing'
   & "$root\psnr.ps1" -Dir "$root\runtime-regression-$ph-q0"|Tee-Object "$root\psnr-$ph.txt"
   foreach($r in 1..$Rounds){& "$root\regression.ps1" -Set $ph -BenchName benchmark-base2.exe -Base A -CandidateBenchName benchmark-F2.exe -CandidateExtra $fn -TimingOnly -TimingFrames 1000 -Batch "timing-$r" *> "$root\timing-$ph-$r.log"}}
  & "$root\summarize.ps1" -Sets $ph|Tee-Object "$root\abba-$ph.txt"
  & "$root\p99m.ps1" -Set $ph|Tee-Object -Append "$root\abba-$ph.txt"
  Get-ChildItem $root -Recurse -Include *.f16,*.ppm -EA 0|?{$_.FullName -match 'runtime-regression'}|Remove-Item -Force -EA 0}
} catch {"GO FAIL $_"} finally {Get-ChildItem $root -Recurse -Include *.f16,*.ppm -EA 0|?{$_.FullName -match 'runtime-regression'}|Remove-Item -Force -EA 0;if((Test-Path $L) -and ((Get-Content $L) -match 'fast-vit')){Remove-Item $L -Force};'LOCK DROPPED'}
'GO_DONE'

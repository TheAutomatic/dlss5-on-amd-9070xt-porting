# go.ps1 (default-swap): GPU lock + game check, then phases. Base everywhere = installed default (benchmark-F + flat-I, lab flags: skip 42,43,46,
# FAST_NUMERIC unset) = A. Timing phases (ABBA, 1000 frames, default sequence, 900+1080): B = skip none, C = skip none + FAST_NUMERIC=1,
# D = FAST_NUMERIC=1. Phase Q = PSNR, 7 cases x 12 frames, reference B (base side gets SKIP_BLOCKS=): QA = A, QC = C, QD = D.
param([string[]]$Phases=@('B','C','D','Q'),[int]$Rounds=3)
$root='D:\DLSSNR-Lab\hip-backend\default-swap-20261003';$L='D:\DLSSNR-Lab\gpu.lock'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"default-swap $(Get-Date -Format s)"|Out-File -Encoding ascii $L
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
$ns='DLSS5_SKIP_BLOCKS=';$fn='DLSS5_FAST_NUMERIC=1';$ex=@{B=@($ns);C=@($ns,$fn);D=@($fn);QA=@('DLSS5_SKIP_BLOCKS=42,43,46');QC=@($ns,$fn);QD=@($fn)}
try{$Phases=@($Phases|%{$_ -split ","}|?{$_})
 foreach($ph in $Phases){"== $ph $(Get-Date -Format T)"
  if($ph -eq 'Q'){foreach($q in 'QA','QC','QD'){Get-ChildItem $root -Directory -Filter "runtime-regression-$q-*"|Remove-Item -Recurse -Force
    Remove-Item "$root\flat-$q" -Recurse -Force -EA 0;Copy-Item "$root\flat-I" "$root\flat-$q" -Recurse
    & "$root\regression-cmp.ps1" -Set $q -Adaptive 0 -BenchName benchmark-F.exe -Base I -CandidateBenchName benchmark-F.exe -BaseExtra $ns -CandidateExtra $ex[$q] -CorrectnessOnly -Batch q0 *> "$root\cmp-$q.log"
    Select-String -Path "$root\cmp-$q.log" -Pattern '^CMP';"-- $q vs B";& "$root\psnr.ps1" -Dir "$root\runtime-regression-$q-q0"|Tee-Object "$root\psnr-$q.txt"
    Get-ChildItem "$root\runtime-regression-$q-q0" -Recurse -Include *.f16,*.ppm -EA 0|Remove-Item -Force -EA 0};continue}
  Get-ChildItem $root -Directory -Filter "runtime-regression-$ph-*"|Remove-Item -Recurse -Force
  Remove-Item "$root\flat-$ph" -Recurse -Force -EA 0;Copy-Item "$root\flat-I" "$root\flat-$ph" -Recurse
  foreach($r in 1..$Rounds){& "$root\regression.ps1" -Set $ph -BenchName benchmark-F.exe -Base I -CandidateBenchName benchmark-F.exe -CandidateExtra $ex[$ph] -TimingOnly -TimingFrames 1000 -Batch "timing-$r" *> "$root\timing-$ph-$r.log"
   if($LASTEXITCODE -or (Select-String -Path "$root\timing-$ph-$r.log" -Pattern 'Exception|failed|throw' -Quiet)){"TIMING $ph $r FAIL";Get-Content "$root\timing-$ph-$r.log" -Tail 5}}
  & "$root\summarize.ps1" -Sets $ph|Tee-Object "$root\abba-$ph.txt";& "$root\p99m.ps1" -Set $ph|Tee-Object -Append "$root\abba-$ph.txt"
  Get-ChildItem $root -Recurse -Include *.f16,*.ppm -EA 0|?{$_.FullName -match 'runtime-regression'}|Remove-Item -Force -EA 0}
} catch {"GO FAIL $_"} finally { Get-ChildItem $root -Recurse -Include *.f16,*.ppm -EA 0|?{$_.FullName -match 'runtime-regression'}|Remove-Item -Force -EA 0; if((Test-Path $L) -and ((Get-Content $L) -match 'default-swap')){Remove-Item $L -Force}; 'LOCK DROPPED' }
'GO_DONE'

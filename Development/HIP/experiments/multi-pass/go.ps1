# go.ps1 (multi-pass): GPU lock + game check, then phases.
# D  = option unset: full.ps1 (19 SAME incl. AE + rollover, -PinIdle via regression.ps1) + 3 ABBA rounds, candidate host M on flat-M (= flat-A).
# E1 = DLSS5_MULTI_PASS=1 written explicitly: 7 cases x 12 frames must be SAME as base. EX = invalid.ps1 (values 7, 0, abc -> 1 with a stderr line).
# AA = base host on both sides (noise floor), DD = option unset, timing only (more ABBA rounds for D). P2/P3 = DLSS5_MULTI_PASS=2/3: 7 cases x 12 frames twice (q-a/q-b, hashes must match, non-finite count), PSNR vs 1 pass, 2 ABBA rounds.
param([string[]]$Phases=@('D','E1','EX','P2','P3'),[int]$Rounds=3)
$root='D:\DLSSNR-Lab\hip-backend\multi-pass-20261003';$L='D:\DLSSNR-Lab\gpu.lock'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"multi-pass $(Get-Date -Format s)"|Out-File -Encoding ascii $L
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
function Hashes($dir){Get-ChildItem $dir -Recurse -Filter *frame-*.f16|?{$_.Directory.Name -match '-True$'}|Sort-Object FullName|%{"$($_.Directory.Name)/$($_.Name) $((Get-FileHash $_.FullName).Hash)"}}
try{$Phases=@($Phases|%{$_ -split ","}|?{$_})
 foreach($ph in $Phases){"== $ph $(Get-Date -Format T)"
  Get-ChildItem $root -Directory -Filter "runtime-regression-$ph-*"|Remove-Item -Recurse -Force
  Remove-Item "$root\flat-$ph" -Recurse -Force -EA 0;Copy-Item "$root\flat-M" "$root\flat-$ph" -Recurse
  if($ph -eq 'D'){try{& "$root\full.ps1" -Set D -Rounds $Rounds -CandHost M -RollHost Mroll *> "$root\full-D.log";"FULL D OK"}catch{"FULL D FAIL $_"}
   "SAME-count D: $((Select-String -Path "$root\full-D.log" -Pattern '^SAME|AE CSV SAME').Count)"
   Get-Content "$root\full-D.log"|Select-String 'FAIL|changed|throw|Error|DIFF'|Select-Object -Last 5
   & "$root\summarize.ps1" -Sets D|Tee-Object "$root\abba-D.txt";& "$root\p99m.ps1" -Set D|Tee-Object -Append "$root\abba-D.txt"}
  if($ph -eq 'E1'){& "$root\regression.ps1" -Set $ph -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-M.exe -CandidateExtra "DLSS5_MULTI_PASS=1" -CorrectnessOnly -Batch q *> "$root\cmp-$ph.log"
   "SAME-count $ph`: $((Select-String -Path "$root\cmp-$ph.log" -Pattern '^SAME').Count)";Get-Content "$root\cmp-$ph.log"|Select-String 'changed|throw|Error'|Select-Object -Last 3}
  if($ph -eq 'EX'){& "$root\invalid.ps1"}
  if($ph -in 'AA','DD'){$c=if($ph -eq 'AA'){'benchmark-base.exe'}else{'benchmark-M.exe'};foreach($r in 1..$Rounds){& "$root\regression.ps1" -Set $ph -BenchName benchmark-base.exe -Base A -CandidateBenchName $c -TimingOnly -TimingFrames 1000 -Batch "timing-$r" *> "$root\timing-$ph-$r.log"}
   & "$root\summarize.ps1" -Sets $ph|Tee-Object "$root\abba-$ph.txt";& "$root\p99m.ps1" -Set $ph|Tee-Object -Append "$root\abba-$ph.txt"}
  if($ph -in 'P2','P3'){$v=$ph.Substring(1)
   foreach($q in 'q-a','q-b'){& "$root\regression-cmp.ps1" -Set $ph -Adaptive 0 -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-M.exe -CandidateExtra "DLSS5_MULTI_PASS=$v" -CorrectnessOnly -Batch $q *> "$root\cmp-$ph-$q.log";Select-String -Path "$root\cmp-$ph-$q.log" -Pattern '^CMP'}
   $ha=Hashes "$root\runtime-regression-$ph-q-a";$hb=Hashes "$root\runtime-regression-$ph-q-b"
   "REPRO $ph files=$($ha.Count) $(if($ha.Count -eq 84 -and !(Compare-Object $ha $hb)){'SAME'}else{'DIFF'})"
   & "$root\nan.ps1" -Dir "$root\runtime-regression-$ph-q-a"
   & "$root\psnr.ps1" -Dir "$root\runtime-regression-$ph-q-a"|Tee-Object "$root\psnr-$ph.txt"
   $shots="$root\shots";New-Item -ItemType Directory -Force $shots|Out-Null
   foreach($c in '900-static','1080-static','1080-motion'){Copy-Item "$root\runtime-regression-$ph-q-a\$c-True\rgb-frame-11.ppm" "$shots\$c-pass$v.ppm" -Force;Copy-Item "$root\runtime-regression-$ph-q-a\$c-False\rgb-frame-11.ppm" "$shots\$c-pass1.ppm" -Force}
   foreach($r in 1..2){& "$root\regression.ps1" -Set $ph -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-M.exe -CandidateExtra "DLSS5_MULTI_PASS=$v" -TimingOnly -TimingFrames 1000 -Batch "timing-$r" *> "$root\timing-$ph-$r.log"}
   & "$root\summarize.ps1" -Sets $ph|Tee-Object "$root\abba-$ph.txt"}
  Get-ChildItem $root -Recurse -Include *.f16,*.ppm -EA 0|?{$_.FullName -match 'runtime-regression' -and $_.FullName -notmatch '-P[23]-q-'}|Remove-Item -Force -EA 0}
} catch {"GO FAIL $_"} finally { if((Test-Path $L) -and ((Get-Content $L) -match 'multi-pass')){Remove-Item $L -Force}; 'LOCK DROPPED' }
'GO_DONE'

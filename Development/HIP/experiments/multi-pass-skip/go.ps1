# go.ps1 (multi-pass-skip): GPU lock + game check, then phases.
# D  = options unset: full.ps1 correctness (19 groups incl. AE + rollover), main host vs branch host (hotkey code present, not pressed).
# The harness flags are the old release recipe (Magpie 0.23 file: skip 42,43,46, bit-exact numerics); every R/S side adds the current default
# (DLSS5_SKIP_BLOCKS= empty = all 71 blocks, DLSS5_FAST_NUMERIC=1). R1 = that default, one pass (timing reference).
# S0..S3 = DLSS5_MULTI_PASS=3 with DLSS5_MULTI_PASS_SKIP_BLOCKS = (empty) / 42,43,46 / $Aggressive (ViT + C512 up) / $Deep (+ C512 down): 7 cases x 12 frames (q-a),
#   then 2 ABBA timing rounds against the base host's single pass. PSNR of S1/S2 against S0 (= 3 passes, all blocks), not against NVIDIA.
# EX = invalid.ps1 (unset / empty / abc / 99 / 10 = a C64 block the byte-stream pipeline cannot skip -> no extra skip + stderr line).
param([string[]]$Phases=@('D','R1','S0','S1','S2','S3','EX'),[string]$Aggressive='31,32,33,34,35,36,37,38,40,41,42,43,44,45,46,47',[string]$Deep='23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,40,41,42,43,44,45,46,47')
$root='D:\DLSSNR-Lab\hip-backend\multi-pass-skip-20261003';$L='D:\DLSSNR-Lab\gpu.lock'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"multi-pass-skip $(Get-Date -Format s)"|Out-File -Encoding ascii $L
$sets=@{R1=$null;S0='';S1='42,43,46';S2=$Aggressive;S3=$Deep}
function Hashes($dir){Get-ChildItem $dir -Recurse -Filter *frame-*.f16|?{$_.Directory.Name -match '-True$'}|Sort-Object FullName|%{"$($_.Directory.Name)/$($_.Name) $((Get-FileHash $_.FullName).Hash)"}}
try{$Phases=@($Phases|%{$_ -split ","}|?{$_})
 foreach($ph in $Phases){"== $ph $(Get-Date -Format T)"
  Get-ChildItem $root -Directory -Filter "runtime-regression-$ph-*"|Remove-Item -Recurse -Force
  Remove-Item "$root\flat-$ph" -Recurse -Force -EA 0;Copy-Item "$root\flat-M" "$root\flat-$ph" -Recurse
  if($ph -eq 'D'){try{& "$root\full.ps1" -Set D -SkipTiming -CandHost M -RollHost Mroll *> "$root\full-D.log";"FULL D OK"}catch{"FULL D FAIL $_"}
   "SAME-count D: $((Select-String -Path "$root\full-D.log" -Pattern '^SAME|AE CSV SAME').Count)"
   Get-Content "$root\full-D.log"|Select-String 'FAIL|changed|throw|Error|DIFF'|Select-Object -Last 5}
  if($sets.ContainsKey($ph)){$x=@('DLSS5_SKIP_BLOCKS=','DLSS5_FAST_NUMERIC=1')+$(if($ph -eq 'R1'){@('DLSS5_MULTI_PASS=1')}else{@('DLSS5_MULTI_PASS=3',"DLSS5_MULTI_PASS_SKIP_BLOCKS=$($sets[$ph])")})
   & "$root\regression-cmp.ps1" -Set $ph -Adaptive 0 -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-M.exe -CandidateExtra $x -CorrectnessOnly -Batch q-a *> "$root\cmp-$ph.log";Select-String -Path "$root\cmp-$ph.log" -Pattern '^CMP|throw|Error'
   if($ph -notin 'S0','R1'){& "$root\psnr2.ps1" -Ref "$root\runtime-regression-S0-q-a" -Test "$root\runtime-regression-$ph-q-a"|Tee-Object "$root\psnr-$ph.txt"}
   $shots="$root\shots";New-Item -ItemType Directory -Force $shots|Out-Null
   foreach($c in '900-static','1080-static','1080-motion'){Copy-Item "$root\runtime-regression-$ph-q-a\$c-True\rgb-frame-11.ppm" "$shots\$c-$ph.ppm" -Force}
   foreach($r in 1..2){& "$root\regression.ps1" -Set $ph -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-M.exe -CandidateExtra $x -TimingOnly -TimingFrames 1000 -Batch "timing-$r" *> "$root\timing-$ph-$r.log"}
   & "$root\summarize.ps1" -Sets $ph|Tee-Object "$root\abba-$ph.txt"}
  if($ph -eq 'EX'){& "$root\invalid.ps1"}
  Get-ChildItem $root -Recurse -Include *.f16 -EA 0|?{$_.FullName -match 'runtime-regression' -and $_.FullName -notmatch '-(S[0-3]|R1)-q-a'}|Remove-Item -Force -EA 0}
} catch {"GO FAIL $_"} finally { if((Test-Path $L) -and ((Get-Content $L) -match 'multi-pass-skip')){Remove-Item $L -Force}; 'LOCK DROPPED' }
'GO_DONE'

# go.ps1 (outside-net): GPU lock + game check, then the requested steps. Steps: setup, probe, addonQ (19 groups + 3 ABBA for host Q), rt.
param([string[]]$Steps=@('probe'),[string]$Tag='p1',[string[]]$Cands=@('D','DQ'))
$root='D:\DLSSNR-Lab\hip-backend\outside-net-20261002';$L='D:\DLSSNR-Lab\gpu.lock'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"outside-net $(Get-Date -Format s)"|Out-File -Encoding ascii $L
try{$Steps=@($Steps|%{$_ -split ","}|?{$_});$Cands=@($Cands|%{$_ -split ","}|?{$_})
 foreach($st in $Steps){"== $st $(Get-Date -Format T)"
  if($st -eq 'probe'){& "$root\probe.ps1" -Tag $Tag *>&1|Tee-Object "$root\probe-$Tag.txt"}
  if($st -eq 'probeaddon'){& "$root\probe.ps1" -Tag $Tag -SkipRt *>&1|Tee-Object "$root\probe-$Tag.txt"}
  if($st -in 'addonQ','addonN'){$X=$st.Substring(5);Get-ChildItem $root -Directory -Filter "runtime-regression-$X-*"|Remove-Item -Recurse -Force
   try{& "$root\full.ps1" -Set $X -Rounds 3 -CandHost $X -RollHost "${X}roll" *> "$root\full-$X.log";"FULL $X OK"}catch{"FULL $X FAIL $_"}
   "SAME-count $X`: $((Select-String -Path "$root\full-$X.log" -Pattern '^SAME|AE CSV SAME').Count)"
   Get-Content "$root\full-$X.log"|Select-String 'FAIL|changed|throw|Error|DIFF'|Select-Object -Last 10
   & "$root\summarize.ps1" -Sets $X;& "$root\p99m.ps1" -Set $X}
  if($st -eq 'rt'){& "$root\rt.ps1" -Cands $Cands *>&1|Tee-Object "$root\rt-$Tag.txt"}}
} catch {"GO FAIL $_"} finally { Get-ChildItem $root -Recurse -Include *.f16,*.ppm -EA 0|?{$_.FullName -match 'runtime-regression|probe-'}|Remove-Item -Force -EA 0; if((Test-Path $L) -and ((Get-Content $L) -match 'outside-net')){Remove-Item $L -Force}; 'LOCK DROPPED' }
'GO_DONE'

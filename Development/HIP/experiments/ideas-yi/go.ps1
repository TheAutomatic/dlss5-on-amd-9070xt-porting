# go.ps1 (ideas-yi): GPU lock + game check; -Prep builds flat-<Set> = flat-A + listed module files; then full.ps1 for each set.
param([string[]]$Sets=@('F'),[string[]]$Hosts=@('F'),[int]$Rounds=3,[switch]$SkipCorrect,[switch]$SkipTiming)
$root='D:\DLSSNR-Lab\hip-backend\ideas-yi-20261002';$L='D:\DLSSNR-Lab\gpu.lock'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"ideas-yi $(Get-Date -Format s)"|Out-File -Encoding ascii $L
try{$Sets=@($Sets|%{$_ -split ","}|?{$_});$Hosts=@($Hosts|%{$_ -split ","}|?{$_})
 if(!(Test-Path "$root\assets-base")){Copy-Item 'D:\DLSSNR-Lab\hip-backend\outside-net-20261002\assets-base' "$root\assets-base" -Recurse}
 for($i=0;$i -lt $Sets.Count;$i++){$X=$Sets[$i];$H=$Hosts[$i];"== $X host $H $(Get-Date -Format T)"
  Copy-Item "$root\benchmark-$H.exe" "$root\benchmark-${H}roll.exe" -Force
  if(!$SkipTiming){Get-ChildItem $root -Directory -Filter "runtime-regression-$X-timing-*"|Remove-Item -Recurse -Force}
  if(!$SkipCorrect){Get-ChildItem $root -Directory -Filter "runtime-regression-$X-*"|Remove-Item -Recurse -Force}
  try{& "$root\full.ps1" -Set $X -Rounds $Rounds -CandHost $H -RollHost "${H}roll" -SkipCorrect:$SkipCorrect -SkipTiming:$SkipTiming *> "$root\full-$X.log";"FULL $X OK"}catch{"FULL $X FAIL $_"}
  "SAME-count $X`: $((Select-String -Path "$root\full-$X.log" -Pattern '^SAME|AE CSV SAME').Count)"
  Get-Content "$root\full-$X.log"|Select-String 'FAIL|changed|throw|Error|DIFF'|Select-Object -Last 5
  if(!$SkipTiming){& "$root\summarize.ps1" -Sets $X;& "$root\p99m.ps1" -Set $X}}
} catch {"GO FAIL $_"} finally { Get-ChildItem $root -Recurse -Include *.f16,*.ppm -EA 0|?{$_.FullName -match 'runtime-regression'}|Remove-Item -Force -EA 0; if((Test-Path $L) -and ((Get-Content $L) -match 'ideas-yi')){Remove-Item $L -Force}; 'LOCK DROPPED' }
'GO_DONE'

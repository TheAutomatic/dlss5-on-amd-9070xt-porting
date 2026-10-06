# go.ps1 (config-layers): GPU lock + game check, then full.ps1 correctness only (19 groups incl. AE + rollover), base main host vs branch host,
# no option set (the hosts only differ in how config files are read; the bench takes its flags file as an argument).
$root='D:\DLSSNR-Lab\hip-backend\config-layers-20261003';$L='D:\DLSSNR-Lab\gpu.lock'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"config-layers $(Get-Date -Format s)"|Out-File -Encoding ascii $L
try{Get-ChildItem $root -Directory -Filter "runtime-regression-D-*"|Remove-Item -Recurse -Force
 Remove-Item "$root\flat-D" -Recurse -Force -EA 0;Copy-Item "$root\flat-M" "$root\flat-D" -Recurse
 try{& "$root\full.ps1" -Set D -SkipTiming -CandHost M -RollHost Mroll *> "$root\full-D.log";"FULL D OK"}catch{"FULL D FAIL $_"}
 "SAME-count D: $((Select-String -Path "$root\full-D.log" -Pattern '^SAME|AE CSV SAME').Count)"
 Get-Content "$root\full-D.log"|Select-String 'FAIL|changed|throw|Error|DIFF'|Select-Object -Last 5
 Get-ChildItem $root -Recurse -Include *.f16,*.ppm -EA 0|?{$_.FullName -match 'runtime-regression'}|Remove-Item -Force -EA 0
} catch {"GO FAIL $_"} finally { if((Test-Path $L) -and ((Get-Content $L) -match 'config-layers')){Remove-Item $L -Force}; 'LOCK DROPPED' }
'GO_DONE'

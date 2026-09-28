$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\float-fma'
& "$r\regression.ps1" -Set P -Base P -Batch confirm -CorrectnessOnly -Adaptive 1 -Only 1080-history
if($LASTEXITCODE){throw 'confirm replay'}
$base="$r\runtime-regression-P-adaptive\1080-history-True"
foreach($side in 'False','True'){
 $d="$r\runtime-regression-P-confirm\1080-history-$side"
 foreach($f in Get-ChildItem $base -Filter '*frame-*.f16'){
  if((Get-FileHash $f.FullName).Hash -ne (Get-FileHash "$d\$($f.Name)").Hash){throw 'new baseline not repeatable'}
 }
 if((Get-FileHash "$base\adaptive.csv").Hash -ne (Get-FileHash "$d\adaptive.csv").Hash){throw 'AE decisions not repeatable'}
}
'24 repeated AE frames and decision logs match new baseline' | Set-Content "$r\confirm-result.txt"

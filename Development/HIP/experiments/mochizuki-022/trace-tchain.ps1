$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mochizuki-022'
$rows=@(foreach($set in 'S','V','F'){foreach($batch in 'correct','adaptive','wrap','wrapae'){
 if(!(Test-Path "$r\runtime-regression-$set-$batch")){continue}
 foreach($d in Get-ChildItem "$r\runtime-regression-$set-$batch" -Directory){
  $line=Get-Content "$($d.FullName)\run.log"|Where-Object {$_ -like 'TCHAIN *'}
  [pscustomobject]@{set=$set;batch=$batch;case=$d.Name;trace=($line -join ';')}
 }
}})
$rows|Export-Csv "$r\tchain-traces.csv" -NoTypeInformation
$rows|Where-Object {$_.batch -eq 'wrap' -and $_.case -like '*True'}|Format-Table -AutoSize

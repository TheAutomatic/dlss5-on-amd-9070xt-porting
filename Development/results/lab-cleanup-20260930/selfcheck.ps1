$root='D:\DLSSNR-Lab\hip-backend\deep-tail-20260930'
& "$root\full.ps1" -Set A -Cand base -RollHost base -SkipTiming *> "$root\selfcheck-20260930.log"
$csv=Import-Csv D:\DLSSNR-Lab\hip-backend\compiler-versions-20260929\new-baseline-hashes.csv
$bad=0;$ok=0
foreach($row in $csv){$ae=if($row.mode -eq 'AE'){'adaptive'}else{'correct'}
 $p=Get-ChildItem "$root\runtime-regression-A-$ae-base" -Recurse -Filter $row.frame | ?{$_.DirectoryName -match [regex]::Escape($row.case)} | select -first 1
 if(!$p){$bad++;"MISSING $($row.mode) $($row.case) $($row.frame)";continue}
 if((Get-FileHash $p.FullName).Hash -eq $row.sha){$ok++}else{$bad++;"DIFF $($row.mode) $($row.case) $($row.frame) $($p.FullName)"}}
"GOLDEN ok=$ok bad=$bad";Get-Content "$root\selfcheck-20260930.log" -Tail 3

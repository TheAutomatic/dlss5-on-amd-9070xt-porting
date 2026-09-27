$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c32-round2'
$out=@(foreach($d in Get-ChildItem "$r\runtime-regression-CN-census" -Directory){foreach($l in Get-Content "$($d.FullName)\run.log"){if($l -match '^C32_(CENSUS|CALL) '){"case=$($d.Name) $l"}}})
[IO.File]::WriteAllLines("$r\census-detail.txt",$out)
'COLLECTED_CENSUS'

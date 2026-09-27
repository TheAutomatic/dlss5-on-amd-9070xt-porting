$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\vit-c512-aco'
$rows=@(foreach($d in Get-ChildItem "$r\runtime-regression-V-adaptive" -Directory){
 foreach($x in Import-Csv "$($d.FullName)\adaptive.csv" -Header frame,reuse,age,reason,relative,local,image){
  [pscustomobject]@{case=$d.Name;frame=$x.frame;reuse=$x.reuse;age=$x.age;reason=$x.reason;relative=$x.relative;local=$x.local;image=$x.image}
 }
})
$rows|Export-Csv "$r\adaptive-decisions.csv" -NoTypeInformation

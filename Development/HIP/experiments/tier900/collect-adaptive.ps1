$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\tier900'
$rows=@(foreach($set in Get-ChildItem $r -Directory -Filter 'runtime-regression-*-adaptive'){
 foreach($d in Get-ChildItem $set.FullName -Directory){foreach($x in Import-Csv "$($d.FullName)\adaptive.csv" -Header frame,reuse,age,reason,relative,local,image){
  [pscustomobject]@{set=$set.Name;case=$d.Name;frame=$x.frame;reuse=$x.reuse;age=$x.age;reason=$x.reason;relative=$x.relative;local=$x.local;image=$x.image}
 }}
})
$rows|Export-Csv "$r\adaptive-decisions.csv" -NoTypeInformation

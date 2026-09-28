$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\fma-vs-nvidia'
$before=Get-Content "$r\installed-before.json" -Raw | ConvertFrom-Json
if($before.Count -ne 60){throw 'bad snapshot'}
foreach($x in $before){if((Get-FileHash $x.path).Hash -ne $x.sha){throw "Installed file changed $($x.path)"}}
$mods=@();foreach($set in 'A','Z','F','H'){foreach($f in Get-ChildItem "$r\flat-$set" -Filter '*.hsaco'){$mods+=[pscustomobject]@{set=$set;module=$f.Name;sha=(Get-FileHash $f.FullName).Hash}}}
$mods | Export-Csv -NoTypeInformation "$r\module-hashes.csv"
[pscustomobject]@{installed_modules=60;unchanged=$true;Z_C32_same=((Get-FileHash "$r\flat-Z\c32-wave1.hsaco").Hash -eq (Get-FileHash "$r\flat-A\c32-wave1.hsaco").Hash);Z_C64_same=((Get-FileHash "$r\flat-Z\c64-wave2.hsaco").Hash -eq (Get-FileHash "$r\flat-A\c64-wave2.hsaco").Hash)} | ConvertTo-Json | Set-Content "$r\final-identity.json"

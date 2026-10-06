$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\daniel-kernels'
$b=Get-Content "$r\before.json" -Raw|ConvertFrom-Json
$n=0;foreach($p in $b.PSObject.Properties){$n++;if((Get-FileHash $p.Name).Hash -ne $p.Value){throw "Protected file changed $($p.Name)"}}
if($n -ne 64){throw 'snapshot count'}
[pscustomobject]@{checked_files=$n;unchanged=$true;installed=$false;published=$false}|ConvertTo-Json|Set-Content "$r\final-identity.json"

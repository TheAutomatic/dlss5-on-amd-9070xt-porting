$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c32-round2'
& "$r\regression.ps1" -Set CN -BenchName benchmark-census.exe -Batch census -CorrectnessOnly *> "$r\census.log"
if($LASTEXITCODE){throw 'census regression failed'}
Get-Content "$r\census.log"|Select-String 'SAME'

$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\kernel-map'
& "$r\trace.ps1"
if($LASTEXITCODE){throw 'trace'}
& "$r\runtime-check.ps1"
if($LASTEXITCODE){throw 'runtime'}
& "$r\collect-all.ps1"
Get-ChildItem "$r\synthetic" -Filter '*.bin'|ForEach-Object{[pscustomobject]@{file=$_.Name;bytes=$_.Length;sha=(Get-FileHash $_.FullName).Hash}}|Export-Csv "$r\synthetic-manifest.csv" -NoTypeInformation

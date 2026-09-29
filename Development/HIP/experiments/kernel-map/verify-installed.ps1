$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\kernel-map';$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
$hip="$g\DLSS5-AMD\native-game-tiled-assets\HIP";$rows=@()
foreach($line in [IO.File]::ReadAllLines("$r\expected-SHA256SUMS")){
 if(!$line.Trim()){continue};$v=$line -split '\s+';$actual=(Get-FileHash (Join-Path $hip $v[1])).Hash.ToLower()
 if($actual -ne $v[0]){throw "Mismatch $($v[1])"};$rows+=[pscustomobject]@{file=$v[1];sha=$actual}
}
if($rows.Count -ne 60){throw 'Expected 60 modules'}
$rows|Export-Csv "$r\installed-modules.csv" -NoTypeInformation
$installed=[IO.File]::ReadAllLines("$hip\SHA256SUMS")
foreach($row in $rows){if(@($installed|Where-Object{$_ -match ('^'+$row.sha+'\s+'+[regex]::Escape($row.file)+'$')}).Count -ne 1){throw 'Installed manifest mismatch'}}
'ALL 60 MODULES MATCH REPOSITORY AND INSTALLED MANIFEST'

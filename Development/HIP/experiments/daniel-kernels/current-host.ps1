$ErrorActionPreference='Stop'
$r='D:\DLSSNR-Lab\hip-backend\daniel-kernels';$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
$b=Get-Content "$r\before.json" -Raw|ConvertFrom-Json
$rows=@();foreach($p in $b.PSObject.Properties){$now=(Get-FileHash $p.Name).Hash;$rows+=[pscustomobject]@{path=$p.Name;before=$p.Value;current=$now;changed=($p.Value -ne $now)}}
$flags=[IO.File]::ReadAllLines("$g\DLSS5-AMD\native-game-flags.txt") | Where-Object {$_ -match '^DLSS5_DIRECT_IO='}
[pscustomobject]@{files=$rows;direct_io=$flags;read_only=$true}|ConvertTo-Json -Depth 5|Set-Content "$r\current-host.json"
Get-FileHash "$g\dlss5-amd.addon64" | Select-Object Hash
$flags

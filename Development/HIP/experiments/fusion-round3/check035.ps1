$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\fusion-round3';$base='D:\給網友打包\OptiScaler-DLSS5-AMD-0.35'
$hip="$base\DLSS5-AMD\native-game-tiled-assets\HIP"
$manifest=@{};foreach($line in Get-Content "$base\SHA256SUMS.txt"){$manifest[$line.Substring(66).Replace('/','\')]=$line.Substring(0,64)}
$tag=@{};foreach($line in Get-Content "$r\035-SHA256SUMS"){if($line.Trim()){$tag[$line.Substring(66).Replace('/','\')]=$line.Substring(0,64)}}
$rows=@(foreach($f in Get-ChildItem $hip -Filter '*.hsaco' -Recurse){$rel=$f.FullName.Substring($hip.Length+1);$key='DLSS5-AMD\native-game-tiled-assets\HIP\'+$rel;$sha=(Get-FileHash $f.FullName).Hash;if($sha -ne $manifest[$key]){throw "Release manifest mismatch $rel"};[pscustomobject]@{file=$rel;sha=$sha;tag_sha=$tag[$rel];tag_matches=($sha -eq $tag[$rel])}})
if($rows.Count -ne 60){throw '60 modules required'}
if((Get-FileHash "$base\dlss5-amd.addon64").Hash -ne '4151123e78eaa6bc29bd29de900d07d5c10ee4a5381b85031d21a1f9e816d707'){throw '0.35 addon mismatch'}
if(!(Test-Path "$base\DLSS5-AMD\native-game-tiled-assets\noise.f32")){throw '0.35 assets missing noise'}
New-Item -ItemType Directory -Force "$r\flat-035"|Out-Null;Copy-Item "$hip\gfx1201\*.hsaco" "$r\flat-035" -Force
$rows|Export-Csv "$r\035-release-hashes.csv" -NoTypeInformation
$rows|Where-Object{!$_.tag_matches}|Select-Object file,sha
Get-Content "$base\release.json" -Raw

# one-time: snapshot the installed (exact) SHA256SUMS and flags of both games
$R='D:\DLSSNR-Lab\fast-tier';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
$g=@{stellar='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';oni='C:\XboxGames\Onimusha- Way of the Sword\Content'}
foreach($k in $g.Keys){Copy-Item "$($g[$k])\$hip\SHA256SUMS" "$R\exact\$k-SHA256SUMS" -Force;Copy-Item "$($g[$k])\DLSS5-AMD\native-game-flags.txt" "$R\exact\$k-flags.txt" -Force}
# full manifest of every file the switch can touch (for the round-trip check)
$out=foreach($k in $g.Keys){$d=$g[$k];Get-ChildItem "$d\$hip" -Recurse -File|%{"$((Get-FileHash $_.FullName).Hash) $k\$($_.FullName.Substring($d.Length+1))"};"$((Get-FileHash "$d\DLSS5-AMD\native-game-flags.txt").Hash) $k\flags";if(Test-Path "$d\dlss5-amd.addon64"){"$((Get-FileHash "$d\dlss5-amd.addon64").Hash) $k\addon"};if(Test-Path "$d\LmxxfNrRuntime.dll"){"$((Get-FileHash "$d\LmxxfNrRuntime.dll").Hash) $k\runtime"}}
$out|Set-Content "$R\manifest-$((Get-Date).ToString('HHmmss')).txt";$out.Count

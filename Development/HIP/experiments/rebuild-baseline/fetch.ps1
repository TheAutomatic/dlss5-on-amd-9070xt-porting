# snapshot installed Stellar + Onimusha HIP trees, add-on, runtime into installed\
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\rebuild-baseline-20261001'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
Remove-Item "$root\installed" -Recurse -Force -EA 0;New-Item -ItemType Directory -Force "$root\installed\oni"|Out-Null
Copy-Item "$game\$hip" "$root\installed\stellar" -Recurse;Copy-Item "$oni\$hip" "$root\installed\oni\HIP" -Recurse
Copy-Item "$game\dlss5-amd.addon64","$game\DLSS5-AMD\native-game-flags.txt" "$root\installed\";Copy-Item "$oni\LmxxfNrRuntime.dll" "$root\installed\oni\"
Get-ChildItem "$root\installed" -Recurse -File|?{$_.Extension -ne '.s'}|%{"$((Get-FileHash $_.FullName).Hash.Substring(0,8)) $($_.FullName.Substring($root.Length+11))"}
'FETCH_DONE'

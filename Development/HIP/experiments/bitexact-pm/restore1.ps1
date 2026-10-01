$sb='D:\DLSSNR-Lab\hip-backend\bitexact-pm-20261001\backups\stellar-20261001-135929-decwide'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
Copy-Item "$sb\HIP\gfx1200\deep_fast-packed.hsaco" "$game\$hip\gfx1200\" -Force
$bad=@(Get-ChildItem "$sb\HIP" -Recurse -File|?{(Get-FileHash $_.FullName).Hash -ne (Get-FileHash ($_.FullName.Replace("$sb\HIP","$game\$hip"))).Hash}).Count
"stellar HIP diffs vs backup: $bad";& 'D:\DLSSNR-Lab\fast-tier\switch.ps1' -Tier status

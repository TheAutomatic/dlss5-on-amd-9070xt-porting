$g=@('C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64','C:\XboxGames\Onimusha- Way of the Sword\Content')
foreach($d in $g){$d;foreach($n in 'default-config.txt','custom-config.txt','native-game-flags.txt'){$n;Get-Content "$d\DLSS5-AMD\$n"|Select-String '^DLSS5_(PRE_UPSCALE|MULTI_PASS|FAST_NUMERIC|SKIP_BLOCKS)='};Get-ChildItem "$d\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco"|Measure-Object}
Get-Content 'D:\DLSSNR-Lab\hip-backend\fast-vit-20261003\full.ps1'

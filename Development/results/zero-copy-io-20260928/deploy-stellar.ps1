# zero-copy-io: install the DIRECT_IO add-on + input shader into Stellar Blade (backup first). -Restore puts the backup back.
param([switch]$Restore,[string]$Io='3')
$ErrorActionPreference='Stop'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$lab='D:\DLSSNR-Lab\zero-copy-io-20260928'
$files=@('dlss5-amd.addon64','DLSS5-AMD\native-game-tiled-assets\native_game_rgb_input.hlsl','DLSS5-AMD\native-game-flags.txt')
if(Get-Process SB-Win64-Shipping -ErrorAction SilentlyContinue){throw 'game running'}
if($Restore){$b=(Get-ChildItem "$lab\backups" -Directory|Sort-Object Name|Select-Object -Last 1).FullName;foreach($f in $files){Copy-Item "$b\$f" "$g\$f" -Force};"RESTORED from $b";exit}
$b="$lab\backups\stellar-$(Get-Date -Format yyyyMMdd-HHmmss)"
foreach($f in $files){New-Item -ItemType Directory -Force (Split-Path "$b\$f")|Out-Null;Copy-Item "$g\$f" "$b\$f"}
$items=@(Get-ChildItem $b -Recurse -File);$items|ForEach-Object{[pscustomobject]@{file=$_.FullName.Substring($b.Length+1);sha=(Get-FileHash $_.FullName).Hash}}|Export-Csv "$b\manifest.csv" -NoTypeInformation
Copy-Item "$lab\dlss5-amd.addon64" "$g\dlss5-amd.addon64" -Force
Copy-Item "$lab\assets\native_game_rgb_input.hlsl" "$g\DLSS5-AMD\native-game-tiled-assets\native_game_rgb_input.hlsl" -Force
$flags=@(Get-Content "$g\DLSS5-AMD\native-game-flags.txt"|Where-Object{$_ -notmatch '^DLSS5_DIRECT_IO='})+@('# 2026-09-28 zero-copy I/O (3 = input + output direct; 1 = input only; 0 = previous path)',"DLSS5_DIRECT_IO=$Io")
[IO.File]::WriteAllLines("$g\DLSS5-AMD\native-game-flags.txt",$flags)
"INSTALLED backup=$b addon=$((Get-FileHash "$g\dlss5-amd.addon64").Hash) io=$Io"

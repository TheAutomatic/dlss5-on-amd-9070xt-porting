$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
if(Test-Path "$root\snapshot.json"){throw 'Preserve existing snapshot'}
New-Item -ItemType Directory -Force "$root\baseline\gfx1200","$root\baseline\gfx1201"|Out-Null
$rows=@()
foreach($arch in 'gfx1200','gfx1201'){
 $files=@(Get-ChildItem "$game\DLSS5-AMD\native-game-tiled-assets\HIP\$arch" -Filter '*.hsaco')
 if($files.Count -ne 30){throw 'Expected thirty modules per architecture'}
 foreach($f in $files){$h=(Get-FileHash $f.FullName).Hash;Copy-Item $f.FullName "$root\baseline\$arch\$($f.Name)";$rows+=@{path=$f.FullName;arch=$arch;name=$f.Name;sha256=$h}}
}
foreach($f in @("$game\dlss5-amd.addon64","$game\dxgi.dll","$game\OptiScaler.ini","$game\DLSS5-AMD\native-game-flags.txt")){$rows+=@{path=$f;sha256=(Get-FileHash $f).Hash}}
$rows|ConvertTo-Json -Depth 5|Set-Content "$root\snapshot.json"
Copy-Item "$game\DLSS5-AMD\native-game-flags.txt" "$root\base-flags.txt"
$rows|Where-Object{!$_.arch}|ConvertTo-Json
Get-Content "$root\base-flags.txt"|Select-String 'DIRECT_IO|MAKE_RESIDENT|NETWORK_HEIGHT|VIT_ADAPTIVE'
Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile|^jobbench'}|Select-Object Id,ProcessName

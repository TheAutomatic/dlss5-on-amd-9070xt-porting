$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\fusion-round3'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
$hip="$g\DLSS5-AMD\native-game-tiled-assets\HIP"
$expected=@{};foreach($line in Get-Content "$r\expected-final-SHA256SUMS"){if($line.Trim()){$expected[$line.Substring(66).Replace('/','\')]=$line.Substring(0,64)}}
$rows=@(foreach($arch in 'gfx1200','gfx1201'){
 $items=@(Get-ChildItem "$hip\$arch" -Filter '*.hsaco');if($items.Count -ne 30){throw 'architecture count'}
 foreach($f in $items){$key="$arch\$($f.Name)";$sha=(Get-FileHash $f.FullName).Hash.ToLower();if($sha -ne $expected[$key]){throw "Manifest mismatch $key"}
  $frozen="$r\re9-runtime-final\modules\$key";if((Get-FileHash $frozen).Hash.ToLower() -ne $sha){throw "Frozen payload mismatch $key"}
  [pscustomobject]@{arch=$arch;module=$f.Name;sha256=$sha;source=$frozen}
 }
})
if($rows.Count -ne 60 -or $expected.Count -ne 60){throw 'manifest count'}
$rows|Export-Csv "$r\modules-036.csv" -NoTypeInformation
[IO.File]::WriteAllLines("$r\HIP-SHA256SUMS",@($rows|ForEach-Object{"$($_.sha256)  $($_.arch)/$($_.module)"}))
[pscustomobject]@{addon=(Get-FileHash "$g\dlss5-amd.addon64").Hash;runtime=(Get-FileHash "$r\re9-runtime-final\LmxxfNrRuntime.dll").Hash;input_shader=(Get-FileHash "$g\DLSS5-AMD\native-game-tiled-assets\native_game_rgb_input.hlsl").Hash;flags=(Get-FileHash "$g\DLSS5-AMD\native-game-flags.txt").Hash;modules=60}|ConvertTo-Json|Set-Content "$r\package-036-payload.json"
'FINAL 60 MODULES VERIFIED AGAINST REPO AND FROZEN PAYLOAD'

$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\vit-bytestream-20260927';$lab='D:\DLSSNR-Lab\hip-backend\vit-bytestream'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$relhip='DLSS5-AMD\native-game-tiled-assets\HIP'
if((Get-FileHash "$g\dlss5-amd.addon64").Hash -ne '86EF4182EE646C6648D33D561174C6B1C87B33854AE4B1AEA347FFF641485F89'){throw 'Addon baseline changed'}
New-Item -ItemType Directory -Force "$r\payload"|Out-Null
$paths=@('dlss5-amd.addon64')
if(Test-Path "$g\_storage_\dlss5-amd.addon64"){$paths+='_storage_\dlss5-amd.addon64'}
foreach($p in $paths){New-Item -ItemType Directory -Force (Split-Path "$r\payload\$p")|Out-Null;Copy-Item "$lab\dlss5-amd.addon64" "$r\payload\$p" -Force}
$paths+='DLSS5-AMD\native-game-flags.txt';New-Item -ItemType Directory -Force "$r\payload\DLSS5-AMD"|Out-Null
$flags=@(Get-Content "$g\DLSS5-AMD\native-game-flags.txt"|Where-Object{$_ -notmatch '^\s*DLSS5_HIP_VIT_STREAM\s*='})+@('DLSS5_HIP_VIT_STREAM=3')
[IO.File]::WriteAllLines("$r\payload\DLSS5-AMD\native-game-flags.txt",$flags,(New-Object Text.UTF8Encoding($false)))
$sums=if(Test-Path "$g\$relhip\SHA256SUMS"){@(Get-Content "$g\$relhip\SHA256SUMS")}else{@(Get-ChildItem "$g\$relhip" -Recurse -Filter '*.hsaco'|ForEach-Object{$name=$_.FullName.Substring(("$g\$relhip\").Length).Replace('\','/');"$((Get-FileHash $_.FullName).Hash.ToLower())  $name"})}
foreach($a in 'gfx1200','gfx1201'){
 $p="$relhip\$a\vit-stream.hsaco";$paths+=$p
 New-Item -ItemType Directory -Force (Split-Path "$r\payload\$p")|Out-Null
 Copy-Item "$lab\build-stream\$a\vit-stream.hsaco" "$r\payload\$p" -Force
 $sha=(Get-FileHash "$r\payload\$p").Hash.ToLower();$sums=@($sums|Where-Object{$_ -notmatch "\s+$a/vit-stream\.hsaco$"})+@("$sha  $a/vit-stream.hsaco")
}
$paths+="$relhip\SHA256SUMS";[IO.File]::WriteAllLines("$r\payload\$relhip\SHA256SUMS",$sums,(New-Object Text.UTF8Encoding($false)))
$files=@(foreach($p in $paths){[pscustomobject]@{path=$p;baseline=$(if(Test-Path "$g\$p"){(Get-FileHash "$g\$p").Hash}else{$null});candidate=(Get-FileHash "$r\payload\$p").Hash}})
$protected=@(foreach($p in @('dxgi.dll','OptiScaler.ini',"$relhip\gfx1200\c32-wave1.hsaco","$relhip\gfx1201\c32-wave1.hsaco")){[pscustomobject]@{path=$p;sha256=(Get-FileHash "$g\$p").Hash}})
@{files=$files;protected=$protected;flag='DLSS5_HIP_VIT_STREAM=3'}|ConvertTo-Json -Depth 5|Set-Content "$r\payload.json"
'STAGED'

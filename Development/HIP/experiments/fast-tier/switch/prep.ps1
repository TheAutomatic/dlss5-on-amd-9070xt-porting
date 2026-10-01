$ErrorActionPreference='Stop';$R='D:\DLSSNR-Lab\fast-tier'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
Remove-Item "$R\src" -Recurse -Force -EA 0;Expand-Archive "$R\src.zip" "$R\src" -Force
$mods=@{'c32-wave1'='CW_FAST_NUM 3';'c64-wave2'='W2_FAST_NUM 3';'deep_fast-packed'='HIP_DEC_F8W 1'}
foreach($m in $mods.Keys){& "$R\src\build-modules.ps1" -SourceDir "$R\src" -OutputDir "$R\build\$m" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets gfx1200,gfx1201 -Only $m -ExtraDefines @($mods[$m])|Out-Null}
foreach($a in 'gfx1200','gfx1201'){New-Item -ItemType Directory -Force "$R\fast\$a","$R\exact\$a"|Out-Null
 foreach($m in $mods.Keys){Copy-Item "$R\build\$m\$a\$m.hsaco" "$R\fast\$a\" -Force;Copy-Item "$game\$hip\$a\$m.hsaco" "$R\exact\$a\" -Force
  $s=(Get-FileHash "$game\$hip\$a\$m.hsaco").Hash;$o=(Get-FileHash "$oni\$hip\$a\$m.hsaco").Hash
  "$a $m exact $($s.Substring(0,8)) oni $($o.Substring(0,8)) $(if($s -eq $o){'mirror'}else{'DIFF'}) fast $((Get-FileHash "$R\fast\$a\$m.hsaco").Hash.Substring(0,8))"}}
'PREP_DONE'

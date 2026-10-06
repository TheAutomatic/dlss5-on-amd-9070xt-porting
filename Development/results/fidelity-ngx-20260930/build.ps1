$ErrorActionPreference='Stop';$w='D:\DLSSNR-Lab\fidelity-ngx-20260930'
Set-Location $w; tar -xzf hipsrc.tgz
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201'
foreach($t in 'hipb','hips'){
 & "$w\$t\build-modules.ps1" -OutputDir "$w\mods-$t" -Compiler 'D:\DLSSNR-Lab\hip\rtc_compile.exe' -SourceDir "$w\$t" -Targets gfx1201 | Out-Null
 # keep any installed module the recipe does not produce
 Get-ChildItem $g -Filter *.hsaco | ? {!(Test-Path "$w\mods-$t\$($_.Name)")} | % {Copy-Item $_.FullName "$w\mods-$t\"}
 "$t modules=" + (Get-ChildItem "$w\mods-$t" -Filter *.hsaco).Count
}
"installed=" + (Get-ChildItem $g -Filter *.hsaco).Count

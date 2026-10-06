# re-verify FB4 on the new installed baseline (other line installed add-on F2A9C2C4 / C512 modules meanwhile):
# flat-A = installed set with c64-wave2 rolled back to the pre-FB4 module (QF3 backup); flat-FB4N = installed set (FB4).
$root='D:\DLSSNR-Lab\hip-backend\c128-c64-inchain-20261001';$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
$t=Get-Content "$root\regression.ps1" -Raw;$t=$t.Replace('|^rtc_compile','');Set-Content "$root\regression.ps1" $t
Get-ChildItem $root -Directory -Filter 'runtime-regression-*'|Remove-Item -Recurse -Force
foreach($d in 'flat-A','flat-FB4N'){Remove-Item "$root\$d" -Recurse -Force -EA 0;New-Item -ItemType Directory "$root\$d"|Out-Null;Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\$d" -Force}
Copy-Item "$root\backups\stellar-20261001-071423-ffnqb4\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\c64-wave2.hsaco" "$root\flat-A" -Force
"A c64 $((Get-FileHash "$root\flat-A\c64-wave2.hsaco").Hash)  FB4N c64 $((Get-FileHash "$root\flat-FB4N\c64-wave2.hsaco").Hash) addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash)"
try{& "$root\full.ps1" -Set FB4N -Rounds 3 *> "$root\full-FB4N.log";'FULL OK'}catch{"FULL FAIL $_"}
"SAME-count: $((Select-String -Path "$root\full-FB4N.log" -Pattern '^SAME|AE CSV SAME').Count)"
& "$root\summarize.ps1" -Sets FB4N;& "$root\p99m.ps1" -Set FB4N
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force

# FW2 final: flat-E + final c512-m32-deep on host P6 (HEAD) vs flat-E on P6: 19 bit-exact; then install; then RE9 runtime replay/smoke against the pre-install backup
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001'
Remove-Item -Recurse -Force "$root\flat-EF","$root\runtime-regression-EF-*" -EA 0
New-Item -ItemType Directory -Force "$root\flat-EF"|Out-Null;Copy-Item "$root\flat-E\*" "$root\flat-EF";Copy-Item "$root\build-final\gfx1201\c512-m32-deep.hsaco" "$root\flat-EF" -Force
& "$root\full.ps1" -BaseSet E -BaseBench benchmark-P6.exe -Set EF -Cand P6 -RollHost P6 -SkipTiming *> "$root\full-EF.log"
$n=(Select-String "$root\full-EF.log" -Pattern '^SAME|AE CSV SAME').Count;"SAME count $n";if($n -ne 19){throw 'not bit-exact, no install'}
& "$root\install4.ps1"
$bk=(Get-ChildItem D:\DLSSNR-Lab\onimusha-backups -Directory -Filter '*-ffnw2'|Sort-Object Name|Select-Object -Last 1).FullName
(Get-Content "$root\rtcheck.ps1" -Raw).Replace('D:\DLSSNR-Lab\onimusha-backups\20261001-030939-ffnone',$bk)|Set-Content "$root\rtcheck2.ps1"
& "$root\rtcheck2.ps1"

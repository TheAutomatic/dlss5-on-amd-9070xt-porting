$root='D:\DLSSNR-Lab\hip-backend\swin-body-gap-20261001'
$t=Get-Content "$root\regression.ps1" -Raw;$t=$t.Replace('|^rtc_compile','');Set-Content "$root\regression.ps1" $t
Get-ChildItem $root -Directory -Filter 'runtime-regression-LB-*'|Remove-Item -Recurse -Force
try{& "$root\full.ps1" -Set LB -Rounds 3 *> "$root\full-LB.log";'FULL OK'}catch{"FULL FAIL $_"}
Get-Content "$root\full-LB.log" | Select-String 'SAME|FAIL|changed|DONE|throw' | Select-Object -Last 30
& "$root\summarize.ps1" -Sets LB;& "$root\p99m.ps1" -Set LB
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force

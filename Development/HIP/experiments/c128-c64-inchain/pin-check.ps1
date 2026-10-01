# both hosts = new host (knob), -PinIdle: 19 groups must be SAME (pin is consistent when both sides honour it)
$root='D:\DLSSNR-Lab\hip-backend\c128-c64-inchain-20261001'
& "$root\setup.ps1" -PinIdle|Out-Null
$t=Get-Content "$root\regression.ps1" -Raw;$t=$t.Replace('|^rtc_compile','');Set-Content "$root\regression.ps1" $t
Get-ChildItem $root -Directory -Filter 'runtime-regression-*'|Remove-Item -Recurse -Force
Copy-Item "$root\benchmark-P.exe" "$root\benchmark-base.exe" -Force
New-Item -ItemType Directory -Force "$root\flat-PIN"|Out-Null;Copy-Item "$root\flat-A\*.hsaco" "$root\flat-PIN" -Force
try{& "$root\full.ps1" -Set PIN -Rounds 1 *> "$root\full-PIN.log";'FULL OK'}catch{"FULL FAIL $_"}
"SAME-count: $((Select-String -Path "$root\full-PIN.log" -Pattern '^SAME|AE CSV SAME').Count)"
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force
& "$root\setup.ps1"|Out-Null

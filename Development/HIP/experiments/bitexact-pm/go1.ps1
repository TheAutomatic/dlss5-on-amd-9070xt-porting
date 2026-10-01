# step 1: guard check (old decode shader + IO_FUSE=1 must be refused -> SAME), then IOF / DW / DF / DWF each 19 groups + 3 ABBA rounds
$root='D:\DLSSNR-Lab\hip-backend\bitexact-pm-20261001'
"== G (guard: IO_FUSE=1 with the installed decode shader)"
Get-ChildItem $root -Directory -Filter 'runtime-regression-G-*'|Remove-Item -Recurse -Force
New-Item -ItemType Directory -Force "$root\flat-G"|Out-Null;Copy-Item "$root\flat-A\*.hsaco" "$root\flat-G" -Force
try{& "$root\full.ps1" -Set G -SkipTiming -Extra @('DLSS5_IO_FUSE=1') *> "$root\full-G.log";'G FULL OK'}catch{"G FULL FAIL $_"}
"G SAME-count: $((Select-String -Path "$root\full-G.log" -Pattern '^SAME|AE CSV SAME').Count)"
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force
"== IOF";& "$root\cand.ps1" -Set IOF -CandAssets -Extra @('DLSS5_IO_FUSE=1')
"== DW";& "$root\cand.ps1" -Set DW -Build DW
"== DF";& "$root\cand.ps1" -Set DF -Build DF
"== DWF";& "$root\cand.ps1" -Set DWF -Build DWF
'GO1_DONE'

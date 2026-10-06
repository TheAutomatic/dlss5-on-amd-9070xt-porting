param([string]$Set='IOF')
$root='D:\DLSSNR-Lab\hip-backend\pending-review-20261003'
$log="$root\full-$Set.log"
if(Test-Path $log){
 Get-Content $log -Tail 8
 "SAME-count: $((Select-String -Path $log -Pattern '^SAME|AE CSV SAME').Count)"
}else{"no log yet"}
"--- timing dirs:"
Get-ChildItem $root -Directory -Filter "runtime-regression-$Set-timing-*" | Select-Object -ExpandProperty Name

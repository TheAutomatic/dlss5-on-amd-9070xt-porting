$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\mh-round1-20260927';$lab='D:\DLSSNR-Lab\hip-backend\mh-round1'
$base=@{};$candidate=@{}
foreach($a in 'gfx1200','gfx1201'){
 New-Item -ItemType Directory -Force "$r\payload\$a"|Out-Null
 Copy-Item "$lab\modules-E\$a\c64-wave2.hsaco" "$r\payload\$a\" -Force
 $base[$a]=(Get-FileHash "$lab\modules-A\$a\c64-wave2.hsaco").Hash
 $candidate[$a]=(Get-FileHash "$r\payload\$a\c64-wave2.hsaco").Hash
}
@{baseline=$base;candidate=$candidate;defines=@('W2_BYTE_INPUT_LOADS 1','W2_RTZ_PAIR 1','W2_DIRECT_COORDS 1');module='c64-wave2';baseline_commit='4937bac'}|ConvertTo-Json -Depth 4|Set-Content "$r\payload.json"
'STAGED'

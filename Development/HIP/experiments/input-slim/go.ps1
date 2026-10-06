$root='D:\DLSSNR-Lab\hip-backend\input-slim-20261001'
& "$root\full.ps1" -Set A -BaseSet A -Cand P -RollHost Proll -Rounds 3 *> "$root\full-F.log"
"full exit $?";Get-Content "$root\full-F.log" | Select-String 'SAME|FAIL|Output changed|DONE|throw|error' | Select-Object -Last 40
& "$root\summarize.ps1" -Sets A;& "$root\p99m.ps1" -Set A

$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\mochizuki-022'
if(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^ledger$|^rt_bench'}){throw 'GPU busy'}
& 'D:\DLSSNR-Lab\hip-backend\c512-round1\resources.exe' $r "$r\resources.csv" > "$r\resources-result.txt"
if($LASTEXITCODE){throw 'Resources query failed'}

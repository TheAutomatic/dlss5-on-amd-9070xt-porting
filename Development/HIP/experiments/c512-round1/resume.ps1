# Run only after the GPU is free. Replays first rebuild confidence, then measure.
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c512-round1'
if(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^benchmark|^ledger$'}){throw 'GPU busy'}
if(Test-Path "$r\1080-pdl1"){
 if(Test-Path "$r\rejected-1080-game"){throw 'Existing rejected archive: inspect before rerun'}
 Move-Item "$r\1080-pdl1" "$r\rejected-1080-game"
}
& "$r\ledger.ps1" -Heights 1080
if($LASTEXITCODE){throw 'Ledger failed'}
& "$r\suite.ps1"
if($LASTEXITCODE){throw 'Suite failed'}
& "$r\collect.ps1"
& "$r\collect-adaptive.ps1"

$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\composite-quant-20260930'
& "$root\mkset.ps1" -Name M -Builds Mc64,Msp
try{& "$root\full.ps1" -Set M -Cand base -RollHost Proll *> "$root\full-M.log";'M OK'}catch{"M FAIL $_"|Tee-Object -Append "$root\full-M.log"}
& "$root\summarize.ps1" -Sets M
'RUN_DONE'

# M = base host + both C512_F_MASK modules: 19-group bitwise + three ABBA rounds.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\composite-quant-c512-20260930'
& "$root\mkset.ps1" -Name M -Builds Mc512,Mdeep
try{& "$root\full.ps1" -Set M -Cand base -RollHost Proll -Rounds 3 *> "$root\full-M.log";'M OK'}catch{"M FAIL $_"|Tee-Object -Append "$root\full-M.log"}
& "$root\summarize.ps1" -Sets M
'RUN_DONE'

# lock -> smoke (k=1 control, k=8) -> unlock. Usage: go.ps1 -K 8 -Rounds 2
param([int]$K=8,[int]$Rounds=2,[int[]]$Heights=@(900,1080))
$root='D:\DLSSNR-Lab\hip-backend\c512-xblock-queue-20261001'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall'}){'GAME RUNNING';exit 1}
& "$root\lock.ps1" take;if($LASTEXITCODE){exit 1}
try{& "$root\timing.ps1" -K $K -Rounds $Rounds -Heights $Heights *> "$root\timing-k$K.log"}catch{"FAIL $_"|Tee-Object -Append "$root\timing-k$K.log"}finally{& "$root\lock.ps1" drop}
& "$root\summarize.ps1" -Filter "runtime-regression-A-k$K-*"
'GO_DONE'

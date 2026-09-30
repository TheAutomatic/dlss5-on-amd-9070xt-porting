# hoist-loads: W2_HOIST_LOADS 15 candidates, one module each vs flat-A (installed); host unchanged.
param([string[]]$Runs=@('HC:h15','SP:sp15'))
$root='D:\DLSSNR-Lab\hip-backend\hoist-loads-20260930'
foreach($r in $Runs){$n,$b=$r -split ':';& "$root\run.ps1" -Name $n -Builds $b -Rounds 3 -NoBuild *> "$root\go-$n.log"}
'GO_DONE'

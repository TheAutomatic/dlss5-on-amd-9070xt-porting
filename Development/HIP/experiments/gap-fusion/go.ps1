# Candidates vs flat-A (installed modules, base host). Candidate host = benchmark-P (gather-fold host; old modules keep old path).
param([string[]]$Runs=@('G:Gd,Gm','T:T'),[int]$Rounds=3)
$root='D:\DLSSNR-Lab\hip-backend\gap-fusion-20260930'
foreach($r in $Runs){$n,$b=$r -split ':';& "$root\run.ps1" -Name $n -Builds $b -Rounds $Rounds -NoBuild *> "$root\go-$n.log"}
'GO_DONE'

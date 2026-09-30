# prod = recipe as committed (must equal installed c32-wave1), T = CW_PREFIX_TAIL_VEC 1. Host unchanged: bit-exact + rollover + 3 ABBA rounds.
param([switch]$NoBuild,[string]$Name='T',[string]$Defs='CW_PREFIX_TAIL_VEC 1',[int]$Rounds=3)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\prefix-post-arith-20260930'
if(!$NoBuild){& "$root\build.ps1" -Name prod -Module c32-wave1;& "$root\build.ps1" -Name $Name -Module c32-wave1 -Defs $Defs}
& "$root\mkset.ps1" -Name $Name -Builds $Name
try{& "$root\full.ps1" -Set $Name -Cand P -RollHost Proll -Rounds $Rounds *> "$root\full-$Name.log";"$Name OK"}catch{"$Name FAIL $_"|Tee-Object -Append "$root\full-$Name.log"}
& "$root\summarize.ps1" -Sets $Name
'RUN_DONE'

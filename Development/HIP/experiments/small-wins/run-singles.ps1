# Singles: flat sets then full (bitwise 18 groups + 2-round ABBA) each; base = benchmark-base + flat-A, candidate = same host + flat-<set>.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\small-wins-20260930'
& "$root\mkset.ps1" -Name I -Builds I
& "$root\mkset.ps1" -Name P -Builds P
& "$root\mkset.ps1" -Name Q -Builds Q
& "$root\mkset.ps1" -Name O -Builds Omix,Ovit
& "$root\mkset.ps1" -Name C -Builds IP,Omix,Ovit
foreach($s in 'Q','O','C','I','P'){try{& "$root\full.ps1" -Set $s -Cand base -RollHost Proll *> "$root\full-$s.log";"$s OK"}catch{"$s FAIL $_"|Tee-Object -Append "$root\full-$s.log"}}
'SINGLES_DONE'

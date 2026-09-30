# Path evidence with benchmark-Proll2 (diagnostic host, prints SP_PLAN ... w16=N and W2_C256 <kernel>):
#  nosp = SP off (SP_CHANNELS=0): C256 through c64-wave2 c256_wave2*_w16, 7 cases x EXACT/AE vs base (persistent) -> must be SAME.
#  sp   = SP on: 900/1080 history through sp_run256_w16, EXACT.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\c256-w16-20260930'
$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
$env:SP_CHANNELS='0'
foreach($ae in 0,1){& "$root\regression.ps1" -Set W -Adaptive $ae -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-Proll2.exe -CorrectnessOnly -Batch "nosp-$ae";if(!$?){throw 'nosp failed'}}
$env:SP_CHANNELS='4';$env:SP_VALIDATE='1';$env:SP_TRACE='1'
& "$root\regression.ps1" -Set W -Adaptive 0 -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-Proll2.exe -CorrectnessOnly -Only @('900-history','1080-history') -Batch "sp-diag";if(!$?){throw 'sp diag failed'}
'DIAG_DONE'

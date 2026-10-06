param([string]$Batch='screen-async')
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929'
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_VALIDATE='1';$env:SP_TRACE='1'
$env:SP_FORCE_TIMEOUT='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
& "$root\regression.ps1" -Set P -BenchName benchmark-base.exe -CandidateBenchName benchmark-sp.exe -CorrectnessOnly -Only @('900-motion','1080-motion') -Batch $Batch
if(!$?){throw 'Screen failed'}

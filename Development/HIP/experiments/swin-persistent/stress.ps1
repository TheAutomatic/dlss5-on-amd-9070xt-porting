$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929'
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_VALIDATE='1';$env:SP_TRACE='1';$env:SP_FORCE_TIMEOUT='0'
$env:SP_TICKET_LIMIT='1024';$env:SP_TICKET_START='4294967290'
foreach($adaptive in 0,1){
 & "$root\regression.ps1" -Set P -Adaptive $adaptive -BenchName benchmark-base.exe -CandidateBenchName benchmark-sp.exe -CorrectnessOnly -Only @('900-history','1080-history') -Batch "roll-$adaptive"
 if(!$?){throw 'Rollover test failed'}
}
$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0';$env:SP_FORCE_TIMEOUT='1'
foreach($adaptive in 0,1){
 & "$root\regression.ps1" -Set P -Adaptive $adaptive -BenchName benchmark-base.exe -CandidateBenchName benchmark-sp.exe -CorrectnessOnly -Only @('900-motion','1080-motion') -Batch "timeout-$adaptive"
 if(!$?){throw 'Timeout fallback test failed'}
}
$env:SP_VALIDATE='0';$env:SP_TRACE='0'
foreach($adaptive in 0,1){
 & "$root\regression.ps1" -Set P -Adaptive $adaptive -BenchName benchmark-base.exe -CandidateBenchName benchmark-sp.exe -CorrectnessOnly -Only @('900-history','1080-history') -Batch "timeout-async-$adaptive"
 if(!$?){throw 'Asynchronous timeout fallback test failed'}
}

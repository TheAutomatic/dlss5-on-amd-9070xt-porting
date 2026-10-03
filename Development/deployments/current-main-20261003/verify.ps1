$ErrorActionPreference='Stop';$root=$PSScriptRoot
if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -ne 'current-main-20261003'){throw 'wrong lock'}
$old='D:\DLSSNR-Lab\hip-backend\fast-vit-20261003'
Copy-Item "$old\benchmark-F2.exe" "$root\benchmark-approved.exe" -Force
New-Item -ItemType Directory -Force "$root\flat-A","$root\flat-M","$root\flat-PF"|Out-Null
Copy-Item "$old\flat-A\*.hsaco" "$root\flat-A" -Force
Copy-Item "$old\flat-PF\*.hsaco" "$root\flat-PF" -Force
Copy-Item "$root\HIP\gfx1201\*.hsaco" "$root\flat-M" -Force
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
foreach($ae in 0,1){
 & "$root\regression.ps1" -Set M -Adaptive $ae -BenchName benchmark-approved.exe -CandidateBenchName benchmark-main.exe -CorrectnessOnly -Batch "normal-$ae" *> "$root\normal-$ae.log"
 if(!$?){throw 'normal regression failed'}
}
foreach($slot in Get-ChildItem "$root\runtime-regression-M-normal-1" -Directory -Filter '*-True'){$base=$slot.FullName.Substring(0,$slot.FullName.Length-4)+'False';if([IO.File]::ReadAllText("$base\adaptive.csv") -cne [IO.File]::ReadAllText("$($slot.FullName)\adaptive.csv")){throw 'AE decisions changed'}}
'AE CSV SAME'
$env:SP_VALIDATE='1';$env:SP_TRACE='1';$env:SP_TICKET_LIMIT='1024';$env:SP_TICKET_START='4294967290'
foreach($ae in 0,1){& "$root\regression.ps1" -Set M -Adaptive $ae -BenchName benchmark-approved.exe -CandidateBenchName benchmark-main.exe -CorrectnessOnly -Only @('900-history','1080-history') -Batch "roll-$ae" *> "$root\roll-$ae.log";if(!$?){throw 'roll regression failed'}}
$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
# For FAST=1 compare freshly built modules to the accepted PF using the same main host, full 71 blocks.
$s=Get-Content "$root\regression.ps1" -Raw
$s=$s.Replace("'DLSS5_FAST_NUMERIC=0'","'DLSS5_FAST_NUMERIC=1','DLSS5_SKIP_BLOCKS='")
[IO.File]::WriteAllText("$root\regression-fast.ps1",$s)
& "$root\regression-fast.ps1" -Set M -Base PF -BenchName benchmark-main.exe -CandidateBenchName benchmark-main.exe -CorrectnessOnly -Batch fast *> "$root\fast.log"
if(!$?){throw 'fast approved PF mismatch'}
$logs=@('normal-0','normal-1','roll-0','roll-1','fast')
foreach($n in $logs){Select-String -Path "$root\$n.log" -Pattern '^SAME'}
'VERIFY_DONE normal19+fast7'

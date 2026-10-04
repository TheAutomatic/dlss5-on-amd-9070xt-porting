$ErrorActionPreference='Stop';$root=$PSScriptRoot
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$b=[Text.Encoding]::UTF8.GetBytes('multipass-direct-rgba-20261004');$f.Write($b,0,$b.Length);$f.Close()
try{
$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
foreach($ae in 0,1){& "$root\regression.ps1" -Set R -Adaptive $ae -Base A -BenchName benchmark-F.exe -CandidateBenchName benchmark-R.exe -CorrectnessOnly -Batch "normal-$ae" *> "$root\normal-$ae.log";if(!$?){throw 'normal failed'}}
foreach($slot in Get-ChildItem "$root\runtime-regression-R-normal-1" -Directory -Filter '*-True'){$b=$slot.FullName.Substring(0,$slot.FullName.Length-4)+'False';if([IO.File]::ReadAllText("$b\adaptive.csv") -cne [IO.File]::ReadAllText("$($slot.FullName)\adaptive.csv")){throw 'AE decisions mismatch'}}
$env:SP_VALIDATE='1';$env:SP_TRACE='1';$env:SP_TICKET_LIMIT='1024';$env:SP_TICKET_START='4294967290'
foreach($ae in 0,1){& "$root\regression.ps1" -Set R -Adaptive $ae -Base A -BenchName benchmark-F.exe -CandidateBenchName benchmark-R.exe -CorrectnessOnly -Only @('900-history','1080-history') -Batch "roll-$ae" *> "$root\roll-$ae.log";if(!$?){throw 'roll failed'}}
$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
$s=Get-Content "$root\regression.ps1" -Raw;$s=$s.Replace("'DLSS5_FAST_NUMERIC=0'","'DLSS5_FAST_NUMERIC=1','DLSS5_SKIP_BLOCKS='").Replace("{32}","{80}")
foreach($pred in 0,1){foreach($round in 1,2,3){$s2=$s.Replace("'DLSS5_MULTI_PASS=1'","'DLSS5_MULTI_PASS=3','DLSS5_MULTI_PASS_PREDICT=$pred','DLSS5_MULTI_PASS_SKIN_PROTECT=0'");[IO.File]::WriteAllText("$root\regression-case.ps1",$s2);& "$root\regression-case.ps1" -Set R -Base A -BenchName benchmark-F.exe -CandidateBenchName benchmark-R.exe -TimingOnly -TimingFrames 320 -Batch "abba-$pred-$round" *> "$root\abba-$pred-$round.log";if(!$?){throw 'ABBA failed'}}}
'FORMAL_DONE normal19 abba-three-rounds-two-modes'
}finally{if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -eq 'multipass-direct-rgba-20261004'){Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}}

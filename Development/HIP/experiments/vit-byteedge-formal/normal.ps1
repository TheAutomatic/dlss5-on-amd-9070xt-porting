$ErrorActionPreference='Stop';$root=$PSScriptRoot;$prev='D:\DLSSNR-Lab\hip-backend\free-res-20261002';$lock='D:\DLSSNR-Lab\gpu.lock'
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$b=[Text.Encoding]::UTF8.GetBytes('vit-byteedge-formal-20261004');$f.Write($b,0,$b.Length);$f.Close()
try{
foreach($ae in 0,1){& "$root\regression.ps1" -Set N -Base A -BenchName benchmark-A.exe -CandidateBenchName benchmark-N.exe -CorrectnessOnly -Adaptive $ae -Batch "normal-$ae" *> "$root\normal-$ae.log";if(!$?){throw 'normal failed'}}
foreach($slot in Get-ChildItem "$root\runtime-regression-N-normal-1" -Directory -Filter '*-True'){$b=$slot.FullName.Substring(0,$slot.FullName.Length-4)+'False';if([IO.File]::ReadAllText("$b\adaptive.csv") -cne [IO.File]::ReadAllText("$($slot.FullName)\adaptive.csv")){throw 'AE CSV mismatch'}}
foreach($ae in 0,1){& "$root\regression.ps1" -Set N -Base A -BenchName benchmark-A.exe -CandidateBenchName benchmark-N.exe -CorrectnessOnly -Adaptive $ae -Only @('900-history','1080-history') -Batch "roll-$ae" *> "$root\roll-$ae.log";if(!$?){throw 'roll failed'}}
}finally{if((Test-Path $lock) -and (Get-Content $lock -Raw).Trim() -eq 'vit-byteedge-formal-20261004'){Remove-Item $lock -Force}}
'NORMAL19_DONE'

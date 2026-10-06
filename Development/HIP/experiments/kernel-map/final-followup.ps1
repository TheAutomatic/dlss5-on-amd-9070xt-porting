$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\kernel-map'
[IO.File]::WriteAllLines("$r\final-repeat-list.txt",@('after-ours-092'))
foreach($n in 1,2){& "$r\run-jobs.ps1" -List final-repeat-list.txt -Batch "final-repeat$n";if($LASTEXITCODE){throw 'final-map repeat'}}
& "$r\build-production.ps1"
if($LASTEXITCODE){throw 'production build'}
& "$r\regression.ps1" -Set F -Batch abba2 -TimingOnly -CandidateBenchName benchmark-production.exe
if($LASTEXITCODE){throw 'production ABBA'}
& "$r\regression.ps1" -Set F -Batch gameflags -GameFlags -CorrectnessOnly -Only 1080-motion -CandidateBenchName benchmark-production.exe
if($LASTEXITCODE){throw 'game flags'}

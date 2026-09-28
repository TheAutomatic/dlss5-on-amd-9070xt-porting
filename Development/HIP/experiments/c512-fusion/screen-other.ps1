$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c512-fusion'
foreach($set in 'D','M','MD','S64','S128','Sboth','W'){
 $runner=switch($set){'M'{'benchmark-m32.exe'};'MD'{'benchmark-m32.exe'};'W'{'benchmark-wave16.exe'};default{'benchmark-base.exe'}}
 $case=if($set -eq 'W'){'900-motion'}else{'1080-motion'}
 & "$r\regression.ps1" -Set $set -Batch screen -CorrectnessOnly -Only $case -CandidateBenchName $runner
 if($LASTEXITCODE){throw 'correctness'}
 & "$r\regression.ps1" -Set $set -Batch screen1 -TimingOnly -TimingFrames 200 -CandidateBenchName $runner
 if($LASTEXITCODE){throw 'timing'}
}

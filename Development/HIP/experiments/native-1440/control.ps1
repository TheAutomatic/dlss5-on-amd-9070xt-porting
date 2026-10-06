$ErrorActionPreference='Stop';$root=$PSScriptRoot;$prev='D:\DLSSNR-Lab\hip-backend\free-res-20261002';$lock='D:\DLSSNR-Lab\gpu.lock'
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$b=[Text.Encoding]::UTF8.GetBytes('native-1440-20261004');$f.Write($b,0,$b.Length);$f.Close()
try{$text=[IO.File]::ReadAllText("$root\regression.ps1").Replace("'DLSS5_FAST_NUMERIC=0'","'DLSS5_FAST_NUMERIC=1'")
foreach($pred in 0,1){$t=$text.Replace("'DLSS5_MULTI_PASS=1'","'DLSS5_MULTI_PASS=3','DLSS5_MULTI_PASS_PREDICT=$pred','DLSS5_MULTI_PASS_SKIN_PROTECT=0'");[IO.File]::WriteAllText("$root\regression-control.ps1",$t);& "$root\regression-control.ps1" -Set C -Base A -BenchName benchmark-A.exe -CandidateBenchName benchmark-C.exe -TimingOnly -TimingFrames 160 -Heights @($(if($pred){900}else{1080})) -Batch "control-$pred" *> "$root\control-$pred.log";if(!$?){throw 'control failed'}}
}finally{if((Test-Path $lock) -and (Get-Content $lock -Raw).Trim() -eq 'native-1440-20261004'){Remove-Item $lock -Force}}
'CONTROL_DONE'

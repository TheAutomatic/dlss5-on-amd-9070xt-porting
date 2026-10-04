$ErrorActionPreference='Stop';$root=$PSScriptRoot;$prev='D:\DLSSNR-Lab\hip-backend\free-res-20261002';$lock='D:\DLSSNR-Lab\gpu.lock'
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$b=[Text.Encoding]::UTF8.GetBytes('native-1440-20261004');$f.Write($b,0,$b.Length);$f.Close()
try{& "$root\regression.ps1" -Set A -Base A -BenchName benchmark-A.exe -CandidateBenchName benchmark-A.exe -SameSet -CorrectnessOnly -Adaptive 1 -Only @('720-motion') -Batch '720-self' *> "$root\720-self.log";if(!$?){throw '720 self mismatch'}
}finally{if((Test-Path $lock) -and (Get-Content $lock -Raw).Trim() -eq 'native-1440-20261004'){Remove-Item $lock -Force}}
'SELF_DONE'

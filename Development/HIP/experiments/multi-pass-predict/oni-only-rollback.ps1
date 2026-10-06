$ErrorActionPreference='Stop';$g='C:\XboxGames\Onimusha- Way of the Sword\Content';$root='D:\DLSSNR-Lab\multi-pass-predict-20261004';$backup="$root\backups\20261004-003039\game-1";$fail="$root\failure-20261004"
& 'D:\DLSSNR-Lab\game-check.ps1' Onimusha;if($LASTEXITCODE -ne 1){throw 'Onimusha active'}
if(Get-Process -EA 0|Where-Object{$_.ProcessName -match 'Onimusha'}){throw 'Onimusha process exists'}
$f=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$bytes=[Text.Encoding]::UTF8.GetBytes('oni-rollback-predict-20261004');$f.Write($bytes,0,$bytes.Length);$f.Close()
try{
New-Item -ItemType Directory -Force $fail|Out-Null;foreach($n in 'OptiScaler.log','amd_bridge.log','re2_framework_log.txt'){Copy-Item "$g\$n" "$fail\$n" -Force -EA 0};Copy-Item "$g\DLSS5-AMD\logs" "$fail\logs" -Recurse -Force
foreach($n in 'default-config.txt','custom-config.txt','native-game-flags.txt'){Copy-Item "$g\DLSS5-AMD\$n" "$fail\$n" -Force}
foreach($file in (Get-Content "$backup\manifest.json" -Raw|ConvertFrom-Json)){$dst=Join-Path $g $file.relative;if($file.existed){Copy-Item (Join-Path $backup $file.relative) $dst -Force;if((Get-FileHash $dst).Hash -ne $file.sha256){throw 'readback mismatch'}}else{Remove-Item $dst -Force -EA 0}}
Copy-Item "$g\DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS" 'D:\DLSSNR-Lab\fast-tier\exact\oni-SHA256SUMS' -Force
Copy-Item "$g\DLSS5-AMD\native-game-flags.txt" 'D:\DLSSNR-Lab\fast-tier\exact\oni-flags.txt' -Force
Get-FileHash "$g\LmxxfNrRuntime.dll","$g\_storage_\LmxxfNrRuntime.dll","$g\DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS"|Format-List Path,Hash
foreach($n in 'custom-config.txt','native-game-flags.txt'){"CONFIG $n";Get-Content "$g\DLSS5-AMD\$n"|Select-String -Pattern '^DLSS5_MULTI_PASS(=|_PREDICT=)'}
'ONIMUSHA_ONLY_ROLLBACK_DONE'
}finally{if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -eq 'oni-rollback-predict-20261004'){Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}}

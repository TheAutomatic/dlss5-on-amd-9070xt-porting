$ErrorActionPreference='Stop';$root=$PSScriptRoot
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -ne 'multi-pass-predict-20261004'){throw 'wrong lock'}
Copy-Item "$root\LmxxfNrRuntime.dll" "$root\rt-pred\LmxxfNrRuntime.dll" -Force
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';$env:DLSS5_NETWORK_HEIGHT='1080';$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
$ErrorActionPreference='Continue';& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$root\rt-pred\LmxxfNrRuntime.dll" "$root\rt-pred\modules" > "$root\final-smoke.log" 2> "$root\final-smoke.err";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw 'final smoke failed'};Get-Content "$root\final-smoke.log" -Tail 4;Get-Content "$root\final-smoke.err" -Tail 2
foreach($scope in 'raw','candidate','decoded'){Get-ChildItem "$root\$scope" -File -Recurse|Where-Object{$_.Extension -in '.f32','.f16','.ppm'}|Remove-Item -Force}
foreach($d in Get-ChildItem $root -Directory -Filter 'runtime-regression-*'){Get-ChildItem $d.FullName -Recurse -File -Filter '*.f16'|Remove-Item -Force}
if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -eq 'multi-pass-predict-20261004'){Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}
'FINAL_SMOKE_DONE LOCK_RELEASED'

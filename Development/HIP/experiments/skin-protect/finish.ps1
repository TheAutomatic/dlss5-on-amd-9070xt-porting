$ErrorActionPreference='Stop';$root=$PSScriptRoot
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$bytes=[Text.Encoding]::UTF8.GetBytes('skin-protect-20261004');$f.Write($bytes,0,$bytes.Length);$f.Close()
try{
$s=Get-Content "$root\regression.ps1" -Raw;$s=$s.Replace("'DLSS5_FAST_NUMERIC=0'","'DLSS5_FAST_NUMERIC=1'").Replace("'DLSS5_MULTI_PASS=1'","'DLSS5_MULTI_PASS=3'");[IO.File]::WriteAllText("$root\regression-cost.ps1",$s)
& "$root\regression-cost.ps1" -Set S -BenchName benchmark-prod.exe -CandidateBenchName benchmark-prod.exe -CandidateExtra @('DLSS5_MULTI_PASS_SKIN_PROTECT=1') -TimingOnly -TimingFrames 100 -Batch cost *> "$root\cost.log";if(!$?){throw 'cost failed'}
foreach($case in @(@{n='900-static';t=0},@{n='1080-history';t=1})){foreach($mode in 'skin','predict-skin'){
$orig="$root\raw\$($case.n)-$mode";$d="$root\repeat\$($case.n)-$mode";New-Item -ItemType Directory -Force $d|Out-Null;$flags=@(Get-Content "$orig\flags.txt")+@("DLSS5_MP_RAW_EXPORT=$d");[IO.File]::WriteAllLines("$d\flags.txt",$flags)
$ErrorActionPreference='Continue';& "$root\benchmark.exe" 'D:\DLSSNR-Lab\hip-backend\fast-numeric-20261003\assets-base' "$d\flags.txt" 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16' "$d\rgb" 12 $case.t "$root\flat-S" 0 0 0 0 > "$d\run.log" 2> "$d\run.err";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw 'repeat failed'}
if((Get-FileHash "$orig\final.f32").Hash -ne (Get-FileHash "$d\final.f32").Hash){throw 'repeat differs'};"REPEAT SAME $($case.n)-$mode"
}}
Copy-Item "$root\LmxxfNrRuntime.dll" "$root\probe-new\LmxxfNrRuntime.dll" -Force
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';$env:DLSS5_NETWORK_HEIGHT='1080';$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
$ErrorActionPreference='Continue';& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$root\probe-new\LmxxfNrRuntime.dll" "$root\probe-new\modules" > "$root\smoke.log" 2> "$root\smoke.err";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw 'smoke failed'};Get-Content "$root\smoke.log" -Tail 4
'FINISH_DONE repeat cost smoke'
}finally{if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -eq 'skin-protect-20261004'){Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}}

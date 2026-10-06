$ErrorActionPreference='Stop';$root=$PSScriptRoot;$base='D:\DLSSNR-Lab\current-main-20261003'
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$bytes=[Text.Encoding]::UTF8.GetBytes('multi-pass-predict-20261004');$f.Write($bytes,0,$bytes.Length);$f.Close()
try{
New-Item -ItemType Directory -Force "$root\flat-P"|Out-Null;Copy-Item "$base\flat-M\*.hsaco" "$root\flat-P" -Force;Copy-Item "$root\HIP\gfx1201\multi-pass-predict.hsaco" "$root\flat-P" -Force
foreach($case in @(@{n='900-static';h=900;s=0;t=0},@{n='900-motion';h=900;s=1;t=0},@{n='1080-static';h=1080;s=0;t=0},@{n='1080-motion';h=1080;s=1;t=0},@{n='1080-history';h=1080;s=5;t=1})){
foreach($rep in 1,2){$d="$root\candidate\$($case.n)-$rep";New-Item -ItemType Directory -Force $d|Out-Null;$flags=@(Get-Content "$root\raw\$($case.n)\flags.txt")+@('DLSS5_MULTI_PASS_PREDICT=1',"DLSS5_MP_RAW_EXPORT=$d");[IO.File]::WriteAllLines("$d\flags.txt",$flags)
$ErrorActionPreference='Continue';& "$root\benchmark-predict.exe" 'D:\DLSSNR-Lab\hip-backend\fast-numeric-20261003\assets-base' "$d\flags.txt" 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16' "$d\rgb" 12 $case.t "$root\flat-P" 0 0 0 0 > "$d\run.log" 2> "$d\run.err";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw 'candidate failed'}
(Get-FileHash "$d\final.f32").Hash
}
if((Get-FileHash "$root\candidate\$($case.n)-1\final.f32").Hash -ne (Get-FileHash "$root\candidate\$($case.n)-2\final.f32").Hash){throw 'candidate repeat differs'};"REPEAT SAME $($case.n)"
}}
finally{if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -eq 'multi-pass-predict-20261004'){Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}}
'CANDIDATE_DONE'

$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\multi-pass-predict-20261004';$base='D:\DLSSNR-Lab\current-main-20261003'
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk
if($LASTEXITCODE -ne 1){throw 'Game active'}
if(Get-Process -EA 0|?{$_.ProcessName -match '^benchmark|^rt_bench|^runtime-smoke|^rtc_compile'}){throw 'Lab busy'}
$f=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$b=[Text.Encoding]::UTF8.GetBytes('multi-pass-predict-20261004');$f.Write($b,0,$b.Length);$f.Close()
try{foreach($case in @(@{n='900-static';h=900;s=0;t=0},@{n='900-motion';h=900;s=1;t=0},@{n='1080-static';h=1080;s=0;t=0},@{n='1080-motion';h=1080;s=1;t=0},@{n='1080-history';h=1080;s=5;t=1})){
$d="$root\raw\$($case.n)";New-Item -ItemType Directory -Force $d|Out-Null
$flags=@(Get-Content "$base\runtime-regression-M-fast\$($case.n)-True\flags.txt" -EA SilentlyContinue)
if(!$flags.Count){$flags=@(Get-Content "$base\runtime-regression-M-fast\900-static-True\flags.txt")}
$flags+=@('DLSS5_MULTI_PASS=3',"DLSS5_NETWORK_HEIGHT=$($case.h)","DLSS5_RESIDUAL_SEQUENCE=$($case.s)",'DLSS5_HOT_RELOAD=0',"DLSS5_MP_RAW_EXPORT=$d")
[IO.File]::WriteAllLines("$d\flags.txt",$flags)
$ErrorActionPreference='Continue';& "$root\benchmark-predict.exe" 'D:\DLSSNR-Lab\hip-backend\fast-numeric-20261003\assets-base' "$d\flags.txt" 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16' "$d\rgb" 12 $case.t "$base\flat-M" 0 0 0 0 > "$d\run.log" 2> "$d\run.err";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw 'Replay failed'}
foreach($n in 'x','y1','y2','y3'){Get-FileHash "$d\$n.f32"|Format-Table Hash,Path};Get-ChildItem $d -Filter '*.f16'|Remove-Item
}}
finally{if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -eq 'multi-pass-predict-20261004'){Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}}
'EXPORT_DONE'

$ErrorActionPreference='Stop';$root=$PSScriptRoot;$base='D:\DLSSNR-Lab\current-main-20261003'
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$bytes=[Text.Encoding]::UTF8.GetBytes('multi-pass-predict-20261004');$f.Write($bytes,0,$bytes.Length);$f.Close()
try{
New-Item -ItemType Directory -Force "$root\flat-A"|Out-Null;Copy-Item "$base\flat-M\*.hsaco" "$root\flat-A" -Force;Copy-Item "$base\benchmark-main.exe" "$root\benchmark-base.exe" -Force
$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
foreach($ae in 0,1){& "$root\regression.ps1" -Set P -Adaptive $ae -BenchName benchmark-base.exe -CandidateBenchName benchmark-predict.exe -CorrectnessOnly -Batch "normal-$ae" *> "$root\normal-$ae.log";if(!$?){throw 'normal regression failed'}}
foreach($slot in Get-ChildItem "$root\runtime-regression-P-normal-1" -Directory -Filter '*-True'){$b=$slot.FullName.Substring(0,$slot.FullName.Length-4)+'False';if([IO.File]::ReadAllText("$b\adaptive.csv") -cne [IO.File]::ReadAllText("$($slot.FullName)\adaptive.csv")){throw 'AE decision mismatch'}}
$env:SP_VALIDATE='1';$env:SP_TRACE='1';$env:SP_TICKET_LIMIT='1024';$env:SP_TICKET_START='4294967290'
foreach($ae in 0,1){& "$root\regression.ps1" -Set P -Adaptive $ae -BenchName benchmark-base.exe -CandidateBenchName benchmark-predict.exe -CorrectnessOnly -Only @('900-history','1080-history') -Batch "roll-$ae" *> "$root\roll-$ae.log";if(!$?){throw 'roll failed'}}
$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
# Both hosts with FAST=1, compare normal real MP2/MP3, predictor remains off.
$s=Get-Content "$root\regression.ps1" -Raw
foreach($mp in 2,3){$s2=$s.Replace("'DLSS5_FAST_NUMERIC=0'","'DLSS5_FAST_NUMERIC=1'").Replace("'DLSS5_MULTI_PASS=1'","'DLSS5_MULTI_PASS=$mp'");[IO.File]::WriteAllText("$root\regression-mp.ps1",$s2);& "$root\regression-mp.ps1" -Set P -BenchName benchmark-base.exe -CandidateBenchName benchmark-predict.exe -CorrectnessOnly -Only @('900-motion','1080-history') -Batch "real-$mp" *> "$root\real-$mp.log";if(!$?){throw 'MP compatibility failed'}}
$s3=$s.Replace("'DLSS5_FAST_NUMERIC=0'","'DLSS5_FAST_NUMERIC=1'").Replace("'DLSS5_MULTI_PASS=1'","'DLSS5_MULTI_PASS=3'");[IO.File]::WriteAllText("$root\regression-time.ps1",$s3)
& "$root\regression-time.ps1" -Set P -BenchName benchmark-predict.exe -CandidateBenchName benchmark-predict.exe -CandidateExtra @('DLSS5_MULTI_PASS_PREDICT=1') -TimingOnly -TimingFrames 200 -Batch timing *> "$root\timing.log";if(!$?){throw 'timing failed'}
# Decoded reference for all exported cases, using original export flags except raw export off.
foreach($case in @(@{n='900-static';t=0},@{n='900-motion';t=0},@{n='1080-static';t=0},@{n='1080-motion';t=0},@{n='1080-history';t=1})){
$d="$root\decoded\$($case.n)";New-Item -ItemType Directory -Force $d|Out-Null;$flags=@(Get-Content "$root\raw\$($case.n)\flags.txt")+@('DLSS5_MP_RAW_EXPORT=','DLSS5_MULTI_PASS_PREDICT=0');[IO.File]::WriteAllLines("$d\flags.txt",$flags)
$ErrorActionPreference='Continue';& "$root\benchmark-predict.exe" 'D:\DLSSNR-Lab\hip-backend\fast-numeric-20261003\assets-base' "$d\flags.txt" 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16' "$d\rgb" 12 $case.t "$root\flat-P" 0 0 0 0 > "$d\run.log" 2> "$d\run.err";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw 'decoded reference failed'}
}
'VERIFY_DONE normal19 realMP2/3 timing decoded'
}
finally{if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -eq 'multi-pass-predict-20261004'){Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}}

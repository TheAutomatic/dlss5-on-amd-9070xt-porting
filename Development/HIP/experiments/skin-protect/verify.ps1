$ErrorActionPreference='Stop';$root=$PSScriptRoot;$base='D:\DLSSNR-Lab\current-main-20261003';$prev='D:\DLSSNR-Lab\multi-pass-predict-20261004'
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$bytes=[Text.Encoding]::UTF8.GetBytes('skin-protect-20261004');$f.Write($bytes,0,$bytes.Length);$f.Close()
try{
foreach($side in 'old','new'){New-Item -ItemType Directory -Force "$root\probe-$side\modules","$root\probe-$side\shaders","$root\probe-$side\DLSS5-AMD"|Out-Null;Copy-Item "$root\HIP\*" "$root\probe-$side\modules" -Recurse -Force;Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$root\probe-$side\shaders" -Force;Copy-Item $(if($side -eq 'old'){"$prev\LmxxfNrRuntime.dll"}else{"$root\LmxxfNrRuntime.dll"}) "$root\probe-$side\LmxxfNrRuntime.dll" -Force
$mod="$root\probe-$side\modules";$lines=@(Get-ChildItem $mod -Recurse -Filter '*.hsaco'|Sort-Object FullName|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring($mod.Length+1).Replace('\','/'))"});[IO.File]::WriteAllLines("$mod\SHA256SUMS",$lines)
[IO.File]::WriteAllLines("$root\probe-$side\DLSS5-AMD\native-game-flags.txt",@('DLSS5_SKIP_BLOCKS=','DLSS5_FAST_NUMERIC=1','DLSS5_MULTI_PASS=3','DLSS5_MULTI_PASS_PREDICT=1','DLSS5_MULTI_PASS_SKIN_PROTECT=1'))}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';$env:DLSS5_NETWORK_HEIGHT='900';$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
foreach($side in 'old','new'){$ErrorActionPreference='Continue';& "$root\pending-probe.exe" "$root\probe-$side\LmxxfNrRuntime.dll" "$root\probe-$side\modules" '1707x961' 1 1 > "$root\pending-$side.log" 2> "$root\pending-$side.err";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw 'probe failed'};Get-Content "$root\pending-$side.log"|Select-String -Pattern 'PENDING_PROBE|rt_bench: ok'}
New-Item -ItemType Directory -Force "$root\flat-A","$root\flat-S"|Out-Null;Copy-Item "$base\flat-M\*.hsaco" "$root\flat-A" -Force;Copy-Item "$root\HIP\gfx1201\*.hsaco" "$root\flat-S" -Force;Copy-Item "$base\benchmark-main.exe" "$root\benchmark-base.exe" -Force
$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
foreach($ae in 0,1){& "$root\regression.ps1" -Set S -Adaptive $ae -BenchName benchmark-base.exe -CandidateBenchName benchmark-prod.exe -CorrectnessOnly -Batch "normal-$ae" *> "$root\normal-$ae.log";if(!$?){throw 'normal failed'}}
foreach($slot in Get-ChildItem "$root\runtime-regression-S-normal-1" -Directory -Filter '*-True'){$b=$slot.FullName.Substring(0,$slot.FullName.Length-4)+'False';if([IO.File]::ReadAllText("$b\adaptive.csv") -cne [IO.File]::ReadAllText("$($slot.FullName)\adaptive.csv")){throw 'AE decisions mismatch'}}
$env:SP_VALIDATE='1';$env:SP_TRACE='1';$env:SP_TICKET_LIMIT='1024';$env:SP_TICKET_START='4294967290'
foreach($ae in 0,1){& "$root\regression.ps1" -Set S -Adaptive $ae -BenchName benchmark-base.exe -CandidateBenchName benchmark-prod.exe -CorrectnessOnly -Only @('900-history','1080-history') -Batch "roll-$ae" *> "$root\roll-$ae.log";if(!$?){throw 'roll failed'}}
$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
foreach($case in @(@{n='900-static';h=900;s=0;t=0},@{n='1080-motion';h=1080;s=1;t=0},@{n='1080-history';h=1080;s=5;t=1})){
foreach($mode in @(@{n='one';p=1;pred=0;skin=0},@{n='one-skin';p=1;pred=0;skin=1},@{n='three';p=3;pred=0;skin=0},@{n='skin';p=3;pred=0;skin=1},@{n='predict-skin';p=3;pred=1;skin=1})){
$d="$root\raw\$($case.n)-$($mode.n)";New-Item -ItemType Directory -Force $d|Out-Null;$flags=@(Get-Content "$base\runtime-regression-M-fast\900-static-True\flags.txt")+@("DLSS5_NETWORK_HEIGHT=$($case.h)","DLSS5_RESIDUAL_SEQUENCE=$($case.s)",'DLSS5_HOT_RELOAD=0',"DLSS5_MULTI_PASS=$($mode.p)","DLSS5_MULTI_PASS_PREDICT=$($mode.pred)","DLSS5_MULTI_PASS_SKIN_PROTECT=$($mode.skin)","DLSS5_MP_RAW_EXPORT=$d");[IO.File]::WriteAllLines("$d\flags.txt",$flags)
$ErrorActionPreference='Continue';& "$root\benchmark.exe" 'D:\DLSSNR-Lab\hip-backend\fast-numeric-20261003\assets-base' "$d\flags.txt" 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16' "$d\rgb" 12 $case.t "$root\flat-S" 0 0 0 0 > "$d\run.log" 2> "$d\run.err";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw 'quality failed'}
}
if((Get-FileHash "$root\raw\$($case.n)-one\final.f32").Hash -ne (Get-FileHash "$root\raw\$($case.n)-one-skin\final.f32").Hash){throw 'MP1 skin changed output'}
"ONE SAME $($case.n)"
}
'VERIFY_DONE normal19 MP1SAME pending_probe quality'
}finally{if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -eq 'skin-protect-20261004'){Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}}

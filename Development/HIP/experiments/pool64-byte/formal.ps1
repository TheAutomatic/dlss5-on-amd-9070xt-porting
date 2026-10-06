$ErrorActionPreference='Stop';$r=$PSScriptRoot;$lock='D:\DLSSNR-Lab\gpu.lock'
function Idle{& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}}
Idle;$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$b=[Text.Encoding]::UTF8.GetBytes('pool64-byte-20261005');$f.Write($b,0,$b.Length);$f.Close()
try{
$assets='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';$mods="$r\HIP\gfx1201";$inputs='D:\DLSSNR-Lab\hip-backend\free-res-20261002\in'
$flags=@(Get-Content 'D:\DLSSNR-Lab\release-041\scripts\hip-game-flags.txt')+@('DLSS5_MULTI_PASS=1','DLSS5_MULTI_PASS_PREDICT=1','DLSS5_MULTI_PASS_SKIN_PROTECT=0','DLSS5_VIT_ADAPTIVE=0','DLSS5_NETWORK_HEIGHT=auto','DLSS5_NETWORK_FREE_RES=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0')
foreach($res in '1600x900','1920x1080','2560x1440'){$pooled=@{'pool-base'=@();'pool-byte'=@()};foreach($round in 1,2,3){
$wh=$res.Split('x');$env:BENCH_W=$wh[0];$env:BENCH_H=$wh[1];$slot=0;$sums=@();$means=@()
foreach($side in 'pool-base','pool-byte','pool-byte','pool-base'){Idle;$d="$r\formal-$res-$round-$slot";$slot++;New-Item -ItemType Directory -Force $d|Out-Null;[IO.File]::WriteAllLines("$d\flags.txt",$flags)
$ErrorActionPreference='Continue';& "$r\$side.exe" $assets "$d\flags.txt" "$inputs\in-$res.f16" "$d\o" 320 0 $mods 0 1 1 0 > "$d\run.log" 2> "$d\stderr.log";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw "runner $rc"}
$v=@(Import-Csv "$d\o.csv"|Where-Object{[int]$_.frame -ge 80}|%{[double]$_.wall_ms});$avg=($v|Measure-Object -Average).Average;$means+=$avg;$pooled[$side]+=$v;$sums+=(Get-FileHash "$d\o.f16").Hash;"FORMAL round=$round $res slot=$($slot-1) side=$side avg=$avg"
}
if(@($sums|Select-Object -Unique).Count -ne 1){throw 'copy output mismatch'};"OUTPUT_SAME $res";$delta=($means[1]+$means[2]-$means[0]-$means[3])/2;"ROUND_DELTA $res $round $delta";if($delta -ge 0){throw "SLOW_ROUND $res $round $delta"}
}
$summary=@{};foreach($side in 'pool-base','pool-byte'){$sorted=@($pooled[$side]|Sort-Object);$summary[$side]=@{avg=($sorted|Measure-Object -Average).Average;p99=$sorted[[math]::Ceiling(.99*$sorted.Count)-1];samples=$sorted.Count}};$summary|ConvertTo-Json -Depth 4|Set-Content "$r\formal-$res-summary.json";"POOLED $res base=$($summary['pool-base'].avg)/$($summary['pool-base'].p99) direct=$($summary['pool-byte'].avg)/$($summary['pool-byte'].p99)";if($summary['pool-byte'].p99 -gt $summary['pool-base'].p99){throw "TAIL_REGRESSION $res"}
}
}finally{if((Test-Path $lock) -and (Get-Content $lock -Raw).Trim() -eq 'pool64-byte-20261005'){Remove-Item $lock}}

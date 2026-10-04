$ErrorActionPreference='Stop';$r=$PSScriptRoot;$lock='D:\DLSSNR-Lab\gpu.lock'
function Idle{& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}}
Idle;$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$b=[Text.Encoding]::UTF8.GetBytes('final-output-direct-20261005');$f.Write($b,0,$b.Length);$f.Close()
try{
$assets='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';$mods='D:\DLSSNR-Lab\release-041\HIP\gfx1201';$inputs='D:\DLSSNR-Lab\hip-backend\free-res-20261002\in'
$flags=@(Get-Content 'D:\DLSSNR-Lab\release-041\scripts\hip-game-flags.txt')+@('DLSS5_MULTI_PASS=1','DLSS5_MULTI_PASS_PREDICT=1','DLSS5_MULTI_PASS_SKIN_PROTECT=0','DLSS5_VIT_ADAPTIVE=0','DLSS5_NETWORK_HEIGHT=auto','DLSS5_NETWORK_FREE_RES=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0')
foreach($res in '1600x900','1920x1080','2560x1440'){
$wh=$res.Split('x');$env:BENCH_W=$wh[0];$env:BENCH_H=$wh[1];$slot=0;$sums=@()
foreach($side in 'base','direct','direct','base'){Idle;$d="$r\screen-$res-$slot";$slot++;New-Item -ItemType Directory -Force $d|Out-Null;[IO.File]::WriteAllLines("$d\flags.txt",$flags)
$ErrorActionPreference='Continue';& "$r\$side.exe" $assets "$d\flags.txt" "$inputs\in-$res.f16" "$d\o" 192 0 $mods 0 1 1 0 > "$d\run.log" 2> "$d\stderr.log";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw "runner $rc"}
$v=@(Import-Csv "$d\o.csv"|Where-Object{[int]$_.frame -ge 80}|%{[double]$_.wall_ms});$avg=($v|Measure-Object -Average).Average;$sums+=(Get-FileHash "$d\o.f16").Hash;"SCREEN $res slot=$($slot-1) side=$side avg=$avg"
}
if(@($sums|Select-Object -Unique).Count -ne 1){throw 'copy output mismatch'};"OUTPUT_SAME $res"
}
}finally{if((Test-Path $lock) -and (Get-Content $lock -Raw).Trim() -eq 'final-output-direct-20261005'){Remove-Item $lock}}

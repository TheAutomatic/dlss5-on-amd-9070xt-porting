$ErrorActionPreference='Stop';$root=$PSScriptRoot;$lock='D:\DLSSNR-Lab\gpu.lock'
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$b=[Text.Encoding]::UTF8.GetBytes('c512-direct-whole-20261004');$f.Write($b,0,$b.Length);$f.Close()
try{$prev='D:\DLSSNR-Lab\hip-backend\free-res-20261002';$base=@(Get-Content "$root\correct-N\flags.txt")
$env:BENCH_W='2560';$env:BENCH_H='1440';$env:BENCH_RAW_OUTPUT='1'
Remove-Item Env:BENCH_RAW_OUTPUT -EA 0
foreach($res in '1600x900','1920x1080','2560x1440'){$wh=$res.Split('x');$env:BENCH_W=$wh[0];$env:BENCH_H=$wh[1];foreach($round in 1,2,3){$slot=0;foreach($s in 'A','N','N','A'){$d="$root\timing-$res-$round-$slot";$slot++;New-Item -ItemType Directory -Force $d|Out-Null;[IO.File]::WriteAllLines("$d\flags.txt",$base+@('DLSS5_MULTI_PASS=1','DLSS5_MULTI_PASS_PREDICT=0'));$ErrorActionPreference='Continue';& "$root\ngx.exe" "$root\assets" "$d\flags.txt" "D:\DLSSNR-Lab\hip-backend\free-res-20261002\in\in-$res.f16" "$d\o" 320 0 "$root\flat-$s" 0 1 1 0 > "$d\run.log" 2> "$d\stderr.log";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw 'timing failed'};$v=@(Import-Csv "$d\o.csv"|Select-Object -Skip 80|%{[double]$_.wall_ms});"TIMING $res $round $s avg=$((($v|Measure-Object -Average).Average))"}}}
}finally{if((Get-Content $lock -Raw).Trim() -eq 'c512-direct-whole-20261004'){Remove-Item $lock -Force}}

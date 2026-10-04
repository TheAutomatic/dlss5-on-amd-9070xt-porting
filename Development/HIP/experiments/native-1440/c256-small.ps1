$ErrorActionPreference='Stop';$root=$PSScriptRoot;$prev='D:\DLSSNR-Lab\hip-backend\free-res-20261002';$lock='D:\DLSSNR-Lab\gpu.lock'
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$b=[Text.Encoding]::UTF8.GetBytes('native-1440-20261004');$f.Write($b,0,$b.Length);$f.Close()
try{$prev='D:\DLSSNR-Lab\hip-backend\free-res-20261002';$base=@(Get-Content "$root\baseline-single-2560x1440\flags.txt"|?{$_ -notmatch '^DLSS5_MULTI_PASS'})
$env:BENCH_W='2560';$env:BENCH_H='1440';$env:BENCH_RAW_OUTPUT='1'
foreach($mode in @(@{n='single';mp=1;pred=0},@{n='pred3';mp=3;pred=1})){foreach($side in 0,1){$d="$root\c256-$($mode.n)-$side";New-Item -ItemType Directory -Force $d|Out-Null;[IO.File]::WriteAllLines("$d\flags.txt",$base+@("DLSS5_MULTI_PASS=$($mode.mp)","DLSS5_MULTI_PASS_PREDICT=$($mode.pred)","DLSS5_LAB_C2561440=$side"));$ErrorActionPreference='Continue';& "$root\ngx-c256.exe" "$root\assets" "$d\flags.txt" "$prev\in\in-2560x1440.f16" "$d\o" 32 0 "$root\flat" 0 0 1 0 > "$d\run.log" 2> "$d\stderr.log";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw "candidate failed $rc"};Select-String "$d\run.log" -Pattern 'GEOMETRY|RAW|RESULT'|%{$_.Line}}
$hs=@(0,1|%{(Get-FileHash "$root\c256-$($mode.n)-$_\o.raw.f32").Hash});if($hs[0] -ne $hs[1]){throw "RAW mismatch $($mode.n)"};"RAW SAME $($mode.n) $($hs[0])"}
}finally{if((Test-Path $lock) -and (Get-Content $lock -Raw).Trim() -eq 'native-1440-20261004'){Remove-Item $lock -Force}}
'C256_SMALL_DONE'

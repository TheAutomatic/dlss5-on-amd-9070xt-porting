$ErrorActionPreference='Stop';$r=$PSScriptRoot;$lock='D:\DLSSNR-Lab\gpu.lock'
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$bytes=[Text.Encoding]::UTF8.GetBytes('sp1440-fast-20261005');$f.Write($bytes,0,$bytes.Length);$f.Close()
try{
$base=@(Get-Content 'D:\DLSSNR-Lab\release-041\scripts\hip-game-flags.txt');$assets='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';$inputs='D:\DLSSNR-Lab\hip-backend\free-res-20261002\in';$env:BENCH_RAW_OUTPUT='1'
$cases=@(@{n='900-old';res='1600x900';fn=1;mp=1;seq=0;hist=0;graph=0;pdl=1;missing=0},@{n='1080-old';res='1920x1080';fn=1;mp=1;seq=0;hist=0;graph=0;pdl=1;missing=0},@{n='1440-normal';res='2560x1440';fn=0;mp=1;seq=0;hist=0;graph=0;pdl=1;missing=0},@{n='1440-missing';res='2560x1440';fn=1;mp=1;seq=0;hist=0;graph=0;pdl=1;missing=1},@{n='1440-motion';res='2560x1440';fn=1;mp=1;seq=1;hist=0;graph=0;pdl=1;missing=0},@{n='1440-predhistory';res='2560x1440';fn=1;mp=3;seq=5;hist=1;graph=0;pdl=1;missing=0},@{n='1440-graph';res='2560x1440';fn=1;mp=1;seq=0;hist=0;graph=1;pdl=0;missing=0})
foreach($c in $cases){$wh=$c.res.Split('x');$env:BENCH_W=$wh[0];$env:BENCH_H=$wh[1];$hash=@();$mods=if($c.missing){'D:\DLSSNR-Lab\pool64-byte-20261005\HIP\gfx1201'}else{"$r\HIP\gfx1201"}
foreach($side in 'sp-base','sp-fast'){$d="$r\compat-$($c.n)-$side";New-Item -ItemType Directory -Force $d|Out-Null;$flags=$base+@('DLSS5_NETWORK_HEIGHT=auto','DLSS5_NETWORK_FREE_RES=1',"DLSS5_FAST_NUMERIC=$($c.fn)","DLSS5_MULTI_PASS=$($c.mp)",'DLSS5_MULTI_PASS_PREDICT=1','DLSS5_MULTI_PASS_SKIN_PROTECT=0','DLSS5_VIT_ADAPTIVE=0',"DLSS5_RESIDUAL_SEQUENCE=$($c.seq)","DLSS5_HIP_GRAPH=$($c.graph)","DLSS5_HIP_PDL=$($c.pdl)");[IO.File]::WriteAllLines("$d\flags.txt",$flags)
$ErrorActionPreference='Continue';& "$r\$side.exe" $assets "$d\flags.txt" "$inputs\in-$($c.res).f16" "$d\o" 4 $c.hist $mods 0 0 1 0 > "$d\run.log" 2> "$d\stderr.log";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw "case $($c.n) side $side rc $rc"};$hash+=(Get-FileHash "$d\o.raw.f32").Hash
}
if($hash[0] -ne $hash[1]){throw "RAW different $($c.n)"};"RAW_SAME $($c.n)"
}
}finally{Remove-Item Env:BENCH_RAW_OUTPUT -ErrorAction SilentlyContinue;if((Test-Path $lock) -and (Get-Content $lock -Raw).Trim() -eq 'sp1440-fast-20261005'){Remove-Item $lock}}

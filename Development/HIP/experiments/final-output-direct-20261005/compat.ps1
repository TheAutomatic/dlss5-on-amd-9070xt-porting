$ErrorActionPreference='Stop';$r=$PSScriptRoot;$lock='D:\DLSSNR-Lab\gpu.lock'
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$bytes=[Text.Encoding]::UTF8.GetBytes('final-output-direct-20261005');$f.Write($bytes,0,$bytes.Length);$f.Close()
try{
$assets='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';$mods='D:\DLSSNR-Lab\release-041\HIP\gfx1201';$inputs='D:\DLSSNR-Lab\hip-backend\free-res-20261002\in';$env:BENCH_RAW_OUTPUT='1'
$base=@(Get-Content 'D:\DLSSNR-Lab\release-041\scripts\hip-game-flags.txt')
$cases=@(
@{n='900-mp2';res='1600x900';mp=2;pred=1;skin=0;seq=0;hist=0;ae=0;graph=0;overlap=0},
@{n='1080-true3';res='1920x1080';mp=3;pred=0;skin=0;seq=1;hist=0;ae=0;graph=0;overlap=0},
@{n='1440-predhistory';res='2560x1440';mp=3;pred=1;skin=0;seq=5;hist=1;ae=0;graph=0;overlap=0},
@{n='900-predskin';res='1600x900';mp=3;pred=1;skin=1;seq=1;hist=0;ae=0;graph=0;overlap=0},
@{n='1080-trueskin';res='1920x1080';mp=3;pred=0;skin=1;seq=0;hist=1;ae=0;graph=0;overlap=0},
@{n='900-ae';res='1600x900';mp=1;pred=1;skin=0;seq=1;hist=1;ae=1;graph=0;overlap=0},
@{n='1080-graph';res='1920x1080';mp=1;pred=1;skin=0;seq=0;hist=0;ae=0;graph=1;overlap=0},
@{n='900-overlap';res='1600x900';mp=1;pred=1;skin=0;seq=0;hist=0;ae=0;graph=0;overlap=1})
foreach($c in $cases){$wh=$c.res.Split('x');$env:BENCH_W=$wh[0];$env:BENCH_H=$wh[1];$hashes=@()
foreach($side in 'base','direct'){$d="$r\compat-$($c.n)-$side";New-Item -ItemType Directory -Force $d|Out-Null;$flags=$base+@("DLSS5_MULTI_PASS=$($c.mp)","DLSS5_MULTI_PASS_PREDICT=$($c.pred)","DLSS5_MULTI_PASS_SKIN_PROTECT=$($c.skin)","DLSS5_VIT_ADAPTIVE=$($c.ae)",'DLSS5_NETWORK_HEIGHT=auto','DLSS5_NETWORK_FREE_RES=1',"DLSS5_HIP_GRAPH=$($c.graph)","DLSS5_OVERLAP=$($c.overlap)",'DLSS5_SHOW_FPS=0',"DLSS5_RESIDUAL_SEQUENCE=$($c.seq)")
[IO.File]::WriteAllLines("$d\flags.txt",$flags);$ErrorActionPreference='Continue';& "$r\$side.exe" $assets "$d\flags.txt" "$inputs\in-$($c.res).f16" "$d\o" 6 $c.hist $mods 0 0 1 0 > "$d\run.log" 2> "$d\stderr.log";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw "compat failure $($c.n) $side $rc"}
$hashes+=(Get-FileHash "$d\o.raw.f32").Hash
}
if($hashes[0] -ne $hashes[1]){throw "RAW mismatch $($c.n)"};"RAW_SAME $($c.n) $($hashes[0])"
}
}finally{Remove-Item Env:BENCH_RAW_OUTPUT -ErrorAction SilentlyContinue;if((Test-Path $lock) -and (Get-Content $lock -Raw).Trim() -eq 'final-output-direct-20261005'){Remove-Item $lock}}

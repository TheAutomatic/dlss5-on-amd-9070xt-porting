$ErrorActionPreference='Stop';$r=$PSScriptRoot;$lock='D:\DLSSNR-Lab\gpu.lock'
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$bytes=[Text.Encoding]::UTF8.GetBytes('sp1440-fast-20261005');$f.Write($bytes,0,$bytes.Length);$f.Close()
try{
$mods="$r\HIP";$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
foreach($side in 'sp-base','sp-fast'){$d="$r\rt-$side";New-Item -ItemType Directory -Force "$d\shaders","$d\DLSS5-AMD"|Out-Null;Copy-Item "$r\$side.dll" "$d\LmxxfNrRuntime.dll" -Force;Copy-Item 'D:\DLSSNR-Lab\release-041\source\shaders\*.hlsl' "$d\shaders" -Force}
foreach($c in @(@{n='1440-single';h='auto';mp=1;pred=1},@{n='1440-pred3';h='auto';mp=3;pred=1})){$env:DLSS5_NETWORK_HEIGHT=$c.h;$hash=@()
foreach($side in 'sp-base','sp-fast'){$d="$r\rt-$side";$flags=@(Get-Content 'D:\DLSSNR-Lab\release-041\scripts\hip-re9-flags.txt')+@("DLSS5_MULTI_PASS=$($c.mp)","DLSS5_MULTI_PASS_PREDICT=$($c.pred)",'DLSS5_MULTI_PASS_SKIN_PROTECT=0','DLSS5_VIT_ADAPTIVE=0','DLSS5_NETWORK_FREE_RES=1');[IO.File]::WriteAllLines("$d\DLSS5-AMD\default-config.txt",$flags)
$ErrorActionPreference='Continue';& 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" $mods '2560x1440' 4 1 > "$r\rt-$($c.n)-$side.log" 2> "$r\rt-$($c.n)-$side.err";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw "runtime $rc"};$hash+=[regex]::Match((Get-Content "$r\rt-$($c.n)-$side.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value
}
if(!$hash[0] -or $hash[0] -ne $hash[1]){throw "RE9 mismatch $($c.n)"};"RE9_SAME $($c.n) $($hash[0])"
}
$ErrorActionPreference='Continue';& 'D:\DLSSNR-Lab\release-041\payload\runtime-smoke.exe' "$r\rt-sp-fast\LmxxfNrRuntime.dll" $mods 32 > "$r\smoke.log" 2> "$r\smoke.err";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw "smoke $rc"};Get-Content "$r\smoke.log" -Tail 3
}finally{if((Test-Path $lock) -and (Get-Content $lock -Raw).Trim() -eq 'sp1440-fast-20261005'){Remove-Item $lock}}

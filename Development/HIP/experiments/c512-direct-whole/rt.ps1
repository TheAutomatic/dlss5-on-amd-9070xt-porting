$ErrorActionPreference='Stop';$root=$PSScriptRoot;$prev='D:\DLSSNR-Lab\vit-byteedge-formal-20261004'
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$b=[Text.Encoding]::UTF8.GetBytes('c512-direct-whole-20261004');$f.Write($b,0,$b.Length);$f.Close()
try{Copy-Item 'D:\DLSSNR-Lab\strength-config-20261004\new.dll' "$root\LmxxfNrRuntime.dll" -Force;foreach($a in 'gfx1200','gfx1201'){Copy-Item "$prev\HIP\$a\*" "$root\HIP\$a" -Force -Exclude 'c512-m32-deep.hsaco'};foreach($side in 'old','new'){
$d="$root\rt-$side";New-Item -ItemType Directory -Force "$d\modules","$d\shaders","$d\DLSS5-AMD"|Out-Null;Copy-Item $(if($side -eq 'old'){"$prev\HIP\*"}else{"$root\HIP\*"}) "$d\modules" -Recurse -Force;Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force;Copy-Item $(if($side -eq 'old'){"$root\LmxxfNrRuntime.dll"}else{"$root\LmxxfNrRuntime.dll"}) "$d\LmxxfNrRuntime.dll" -Force
$mods="$d\modules";$lines=@(Get-ChildItem $mods -Filter '*.hsaco' -Recurse|Sort-Object FullName|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring($mods.Length+1).Replace('\','/'))"});[IO.File]::WriteAllLines("$mods\SHA256SUMS",$lines)
}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
foreach($h in 900,1080,1440){foreach($mode in @(@{n='default';mp=1;pred=0;skin=0},@{n='true3';mp=3;pred=0;skin=0},@{n='pred3';mp=3;pred=1;skin=0})){
$env:DLSS5_NETWORK_HEIGHT=$(if($h -eq 1440){'auto'}else{"$h"});$hx=@();foreach($side in 'old','new'){$d="$root\rt-$side";[IO.File]::WriteAllLines("$d\DLSS5-AMD\native-game-flags.txt",@("DLSS5_NETWORK_FREE_RES=$(if($h -eq 1440){1}else{0})",'DLSS5_SKIP_BLOCKS=','DLSS5_FAST_NUMERIC=1',"DLSS5_MULTI_PASS=$($mode.mp)","DLSS5_MULTI_PASS_PREDICT=$($mode.pred)","DLSS5_MULTI_PASS_SKIN_PROTECT=$($mode.skin)"));
$ErrorActionPreference='Continue';& 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" $(if($h -eq 1440){'2560x1440'}else{'1707x961'}) 12 1 > "$root\rt-$side-$h-$($mode.n).log" 2> "$root\rt-$side-$h-$($mode.n).err";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw 'runtime failed'};$hx += [regex]::Match((Get-Content "$root\rt-$side-$h-$($mode.n).log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value}
if(!$hx[0] -or $hx[0] -ne $hx[1]){throw 'runtime mismatch'};"RUNTIME SAME $h $($mode.n) $($hx[0])"
}}
$ErrorActionPreference='Continue';& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$root\rt-new\LmxxfNrRuntime.dll" "$root\rt-new\modules" > "$root\runtime-smoke.log" 2> "$root\runtime-smoke.err";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw 'smoke failed'};Get-Content "$root\runtime-smoke.log" -Tail 4
'RT_DONE'
}finally{if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -eq 'c512-direct-whole-20261004'){Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}}

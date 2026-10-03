$ErrorActionPreference='Stop';$root=$PSScriptRoot
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$bytes=[Text.Encoding]::UTF8.GetBytes('multi-pass-predict-20261004');$f.Write($bytes,0,$bytes.Length);$f.Close()
try{
$oni='C:\XboxGames\Onimusha- Way of the Sword\Content'
foreach($side in 'old','new','pred'){
 $d="$root\rt-$side";New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders","$d\DLSS5-AMD"|Out-Null
 Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force
 Copy-Item $(if($side -eq 'old'){"$oni\LmxxfNrRuntime.dll"}else{"$root\LmxxfNrRuntime.dll"}) "$d\LmxxfNrRuntime.dll" -Force
 foreach($a in 'gfx1200','gfx1201'){Copy-Item $(if($side -eq 'old'){"$oni\DLSS5-AMD\native-game-tiled-assets\HIP\$a\*.hsaco"}else{"D:\DLSSNR-Lab\current-main-20261003\HIP\$a\*.hsaco"}) "$d\modules\$a" -Force}
 $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|Sort-Object FullName|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring(("$d\modules\").Length).Replace('\','/'))"});[IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)
 if($side -ne 'old'){foreach($a in 'gfx1200','gfx1201'){Copy-Item "$root\HIP\$a\multi-pass-predict.hsaco" "$d\modules\$a" -Force}}
 $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|Sort-Object FullName|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring(("$d\modules\").Length).Replace('\','/'))"});[IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)
 [IO.File]::WriteAllLines("$d\DLSS5-AMD\native-game-flags.txt",@('DLSS5_FAST_NUMERIC=0','DLSS5_SKIP_BLOCKS=','DLSS5_MULTI_PASS=1')+$(if($side -eq 'pred'){@('DLSS5_FAST_NUMERIC=1','DLSS5_MULTI_PASS=3','DLSS5_MULTI_PASS_PREDICT=1')}else{@()} ))
}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
foreach($h in 900,1080){$env:DLSS5_NETWORK_HEIGHT="$h";$hashes=@();foreach($side in 'old','new'){foreach($rep in 1,2){$d="$root\rt-$side";$ErrorActionPreference='Continue';& 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$root\rt-$side-$h-$rep.log";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw 'runtime replay failed'};$hashes += [regex]::Match((Get-Content "$root\rt-$side-$h-$rep.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value}}
 if(!$hashes[0] -or @($hashes|Select-Object -Unique).Count -ne 1){throw "runtime mismatch $h $hashes"};"RUNTIME $h SAME $($hashes[0])"
}
foreach($h in 900,1080){$env:DLSS5_NETWORK_HEIGHT="$h";$hashes=@();foreach($rep in 1,2){$d="$root\rt-pred";$ErrorActionPreference='Continue';& 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$root\rt-pred-$h-$rep.log";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw 'pred runtime failed'};$hashes += [regex]::Match((Get-Content "$root\rt-pred-$h-$rep.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value};if(!$hashes[0] -or $hashes[0] -ne $hashes[1]){throw 'pred runtime repeat differs'};"PRED RUNTIME $h REPEAT SAME $($hashes[0])"}
$ErrorActionPreference='Continue';& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe'  "$root\rt-new\LmxxfNrRuntime.dll" "$root\rt-new\modules" *> "$root\runtime-smoke.log";if($LASTEXITCODE){throw 'smoke failed'};Get-Content "$root\runtime-smoke.log" -Tail 4
'RUNTIME_DONE'

}finally{if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -eq 'multi-pass-predict-20261004'){Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}}

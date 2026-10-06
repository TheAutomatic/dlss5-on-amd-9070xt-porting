$ErrorActionPreference='Stop';$root=$PSScriptRoot
$oni='C:\XboxGames\Onimusha- Way of the Sword\Content'
foreach($side in 'old','new'){
 $d="$root\rt-$side";New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders","$d\DLSS5-AMD"|Out-Null
 Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force
 Copy-Item $(if($side -eq 'old'){"$oni\LmxxfNrRuntime.dll"}else{"$root\LmxxfNrRuntime.dll"}) "$d\LmxxfNrRuntime.dll" -Force
 foreach($a in 'gfx1200','gfx1201'){Copy-Item $(if($side -eq 'old'){"$oni\DLSS5-AMD\native-game-tiled-assets\HIP\$a\*.hsaco"}else{"$root\HIP\$a\*.hsaco"}) "$d\modules\$a" -Force}
 $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|Sort-Object FullName|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring(("$d\modules\").Length).Replace('\','/'))"});[IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)
 [IO.File]::WriteAllLines("$d\DLSS5-AMD\native-game-flags.txt",@('DLSS5_FAST_NUMERIC=0','DLSS5_SKIP_BLOCKS=','DLSS5_MULTI_PASS=1'))
}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
foreach($h in 900,1080){$env:DLSS5_NETWORK_HEIGHT="$h";$hashes=@();foreach($side in 'old','new'){foreach($rep in 1,2){$d="$root\rt-$side";& 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$root\rt-$side-$h-$rep.log";if($LASTEXITCODE){throw 'runtime replay failed'};$hashes += [regex]::Match((Get-Content "$root\rt-$side-$h-$rep.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value}}
 if(!$hashes[0] -or @($hashes|Select-Object -Unique).Count -ne 1){throw "runtime mismatch $h $hashes"};"RUNTIME $h SAME $($hashes[0])"
}
& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$root\rt-new\LmxxfNrRuntime.dll" "$root\rt-new\modules" *> "$root\runtime-smoke.log";if($LASTEXITCODE){throw 'smoke failed'};Get-Content "$root\runtime-smoke.log" -Tail 4
'RUNTIME_DONE'

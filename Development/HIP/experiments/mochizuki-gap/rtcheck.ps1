# RE9 runtime smoke after FF install: old = Onimusha backup (runtime + modules before 03:09), new = installed runtime 5D158F68 + installed modules, fallback = new runtime + old modules. rt_bench hash per height must match; then runtime-smoke on new.
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001';$bk='D:\DLSSNR-Lab\onimusha-backups\20261001-030939-ffnone';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content'
$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
if(Get-Process|?{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall'}){throw 'game running'}
foreach($side in 'old','new','fallback'){
 $d="$root\runtime-$side";Remove-Item -Recurse -Force $d -EA 0;New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders"|Out-Null
 $msrc=if($side -eq 'new'){"$oni\$hip"}else{"$bk\$hip"}
 foreach($a in 'gfx1200','gfx1201'){Copy-Item "$msrc\$a\*.hsaco" "$d\modules\$a" -Force}
 Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force
 Copy-Item $(if($side -eq 'old'){"$bk\LmxxfNrRuntime.dll"}else{"$oni\LmxxfNrRuntime.dll"}) "$d\LmxxfNrRuntime.dll" -Force
 $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring(("$d\modules\").Length).Replace('\','/'))"});[IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
foreach($height in 900,1080){foreach($side in 'old','new','fallback'){
 $env:DLSS5_NETWORK_HEIGHT="$height";$d="$root\runtime-$side";$env:LMXXF_SHADER_DIR="$d\shaders"
 & 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$root\runtime-$side-$height.log"
 if($LASTEXITCODE){throw "rt_bench failed $side $height"}}
 $h=@('old','new','fallback'|%{[regex]::Match((Get-Content "$root\runtime-$_-$height.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value})
 "RUNTIME $height old=$($h[0]) new=$($h[1]) fallback=$($h[2]) $(if($h[0] -and $h[0] -eq $h[1] -and $h[0] -eq $h[2]){'SAME'}else{'MISMATCH'})"}
$d="$root\runtime-new";$env:LMXXF_SHADER_DIR="$d\shaders"
& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" *> "$root\runtime-smoke.log"
"SMOKE exit=$LASTEXITCODE";Get-Content "$root\runtime-smoke.log" -Tail 3

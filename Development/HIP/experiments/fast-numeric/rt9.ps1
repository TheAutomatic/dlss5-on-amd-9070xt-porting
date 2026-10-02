# rt9.ps1 (fast-numeric): RE9 runtime replay. old = installed Onimusha runtime + modules; new = branch runtime + installed modules + -fast modules
# (option unset: must equal old); fastenv = new with DLSS5_FAST_NUMERIC=1 in the environment; fastfile = new with the line in
# DLSS5-AMD\native-game-flags.txt next to the DLL (file path of the runtime; must equal fastenv). runtime-smoke on new.
$ErrorActionPreference='Stop';$lab='D:\DLSSNR-Lab\hip-backend\fast-numeric-20261003';$root="$lab\rt";$L='D:\DLSSNR-Lab\gpu.lock'
$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"fast-numeric-rt9 $(Get-Date -Format s)"|Out-File -Encoding ascii $L
try{foreach($side in 'old','new','fastenv','fastfile'){
 $d="$root\runtime-$side";Remove-Item -Recurse -Force $d -EA 0;New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders"|Out-Null
 foreach($a in 'gfx1200','gfx1201'){Copy-Item "$oni\$hip\$a\*.hsaco" "$d\modules\$a" -Force;if($side -ne 'old'){foreach($m in 'c32-wave1-fast','c64-wave2-fast'){Copy-Item "$lab\pre23\$a\$m.hsaco" "$d\modules\$a" -Force}}}
 Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force
 Copy-Item $(if($side -eq 'old'){"$oni\LmxxfNrRuntime.dll"}else{"$lab\bin\rt-F\LmxxfNrRuntime.dll"}) "$d\LmxxfNrRuntime.dll" -Force
 if($side -eq 'fastfile'){New-Item -ItemType Directory -Force "$d\DLSS5-AMD"|Out-Null;[IO.File]::WriteAllLines("$d\DLSS5-AMD\native-game-flags.txt",@('DLSS5_FAST_NUMERIC=1'))}
 $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring(("$d\modules\").Length).Replace('\','/'))"});[IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
foreach($height in 900,1080){foreach($side in 'old','new','fastenv','fastfile'){
 $env:DLSS5_NETWORK_HEIGHT="$height";$d="$root\runtime-$side";$env:LMXXF_SHADER_DIR="$d\shaders"
 if($side -eq 'fastenv'){$env:DLSS5_FAST_NUMERIC='1'}else{Remove-Item Env:\DLSS5_FAST_NUMERIC -EA 0}
 & 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$root\runtime-$side-$height.log"
 if($LASTEXITCODE){throw "rt_bench failed $side $height"}}
 Remove-Item Env:\DLSS5_FAST_NUMERIC -EA 0
 $h=@('old','new','fastenv','fastfile'|%{[regex]::Match((Get-Content "$root\runtime-$_-$height.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value})
 "RUNTIME $height old=$($h[0]) new=$($h[1]) $(if($h[0] -and $h[0] -eq $h[1]){'SAME'}else{'MISMATCH'}) | fastenv=$($h[2]) fastfile=$($h[3]) $(if($h[2] -and $h[2] -eq $h[3] -and $h[2] -ne $h[0]){'FAST-OK'}else{'FAST-CHECK'})"
 Select-String -Path "$root\runtime-fastfile-$height.log" -Pattern 'flags:' |Select-Object -First 1}
$d="$root\runtime-new";$env:LMXXF_SHADER_DIR="$d\shaders"
& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" *> "$root\runtime-smoke.log"
"SMOKE exit=$LASTEXITCODE";Get-Content "$root\runtime-smoke.log" -Tail 3
} finally {if((Test-Path $L) -and ((Get-Content $L) -match 'fast-numeric-rt9')){Remove-Item $L -Force};'LOCK DROPPED'}

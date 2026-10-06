# rt9.ps1 (multi-pass): RE9 runtime replay. old = installed Onimusha runtime + modules; new = branch runtime, same modules, option unset (must equal old);
# mp2env/mp3env = new with DLSS5_MULTI_PASS=2/3 in the environment; mp2file = new with the line in DLSS5-AMD\native-game-flags.txt next to the DLL
# (must equal mp2env, i.e. the RE9 whitelist reads it). Every side is run twice (rerun hash must match). runtime-smoke on new.
$ErrorActionPreference='Stop';$lab='D:\DLSSNR-Lab\hip-backend\multi-pass-20261003';$root="$lab\rt";$L='D:\DLSSNR-Lab\gpu.lock'
$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"multi-pass-rt9 $(Get-Date -Format s)"|Out-File -Encoding ascii $L
try{foreach($side in 'old','new','mp2env','mp2file','mp3env'){
 $d="$root\runtime-$side";Remove-Item -Recurse -Force $d -EA 0;New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders"|Out-Null
 foreach($a in 'gfx1200','gfx1201'){Copy-Item "$oni\$hip\$a\*.hsaco" "$d\modules\$a" -Force}
 Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force
 Copy-Item $(if($side -eq 'old'){"$oni\LmxxfNrRuntime.dll"}else{"$lab\bin\rt-new\LmxxfNrRuntime.dll"}) "$d\LmxxfNrRuntime.dll" -Force
 if($side -eq 'mp2file'){New-Item -ItemType Directory -Force "$d\DLSS5-AMD"|Out-Null;[IO.File]::WriteAllLines("$d\DLSS5-AMD\native-game-flags.txt",@('DLSS5_MULTI_PASS=2'))}
 $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring(("$d\modules\").Length).Replace('\','/'))"});[IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
foreach($height in 900,1080){foreach($side in 'old','new','mp2env','mp2file','mp3env'){foreach($rep in 'a','b'){
 $env:DLSS5_NETWORK_HEIGHT="$height";$d="$root\runtime-$side";$env:LMXXF_SHADER_DIR="$d\shaders"
 if($side -eq 'mp2env'){$env:DLSS5_MULTI_PASS='2'}elseif($side -eq 'mp3env'){$env:DLSS5_MULTI_PASS='3'}else{Remove-Item Env:\DLSS5_MULTI_PASS -EA 0}
 & 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$root\runtime-$side-$height-$rep.log"
 if($LASTEXITCODE){throw "rt_bench failed $side $height"}}}
 Remove-Item Env:\DLSS5_MULTI_PASS -EA 0
 $hx=@{};foreach($side in 'old','new','mp2env','mp2file','mp3env'){foreach($rep in 'a','b'){$hx["$side$rep"]=[regex]::Match((Get-Content "$root\runtime-$side-$height-$rep.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value}}
 $rr=@('old','new','mp2env','mp2file','mp3env'|?{!$hx["${_}a"] -or $hx["${_}a"] -ne $hx["${_}b"]})
 "RUNTIME $height old=$($hx.olda) new=$($hx.newa) $(if($hx.olda -and $hx.olda -eq $hx.newa){'SAME'}else{'MISMATCH'}) | mp2env=$($hx.mp2enva) mp2file=$($hx.mp2filea) $(if($hx.mp2enva -and $hx.mp2enva -eq $hx.mp2filea -and $hx.mp2enva -ne $hx.olda){'MP2-OK'}else{'MP2-CHECK'}) mp3env=$($hx.mp3enva) | rerun $(if($rr.Count){'DIFF '+($rr -join ',')}else{'SAME'})"
 Select-String -Path "$root\runtime-mp2file-$height-a.log" -Pattern 'flags:' |Select-Object -First 1}
$d="$root\runtime-new";$env:LMXXF_SHADER_DIR="$d\shaders"
& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" *> "$root\runtime-smoke.log"
"SMOKE exit=$LASTEXITCODE";Get-Content "$root\runtime-smoke.log" -Tail 3
} finally {if((Test-Path $L) -and ((Get-Content $L) -match 'multi-pass-rt9')){Remove-Item $L -Force};'LOCK DROPPED'}

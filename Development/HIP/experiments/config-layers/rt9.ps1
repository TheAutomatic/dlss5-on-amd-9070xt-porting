# rt9.ps1 (config-layers): RE9 runtime replay. old = installed Onimusha runtime, new = branch runtime; same modules.
# Sides (config folder = DLSS5-AMD next to the DLL; env as in multi-pass rt9 plus nothing else):
#  old / new          no config file                                  -> new must equal old
#  oldN / newDN       old: installed Onimusha native-game-flags.txt; new: default-config.txt (hip-re9 template) + the same native file -> equal
#  newC2              default + custom-config.txt "DLSS5_MULTI_PASS=2"                  -> must differ from newDN (custom works)
#  newC2N1            default + custom MULTI_PASS=2 + native file with MULTI_PASS=1     -> must equal newDN (native wins over custom)
#  mp2env             new, no file, DLSS5_MULTI_PASS=2 in the environment (reference only: no template, so not comparable to newC2)
#  newC1E2            default + custom MULTI_PASS=1, env MULTI_PASS=2                   -> must equal newC2 (environment wins)
# (The 10-03 run compared newC2/newC1E2 with mp2env and printed BAD for both; that expectation was wrong, see the results README.)
$ErrorActionPreference='Stop';$lab='D:\DLSSNR-Lab\hip-backend\config-layers-20261003';$root="$lab\rt";$L='D:\DLSSNR-Lab\gpu.lock'
$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"config-layers-rt9 $(Get-Date -Format s)"|Out-File -Encoding ascii $L
$sides='old','new','oldN','newDN','newC2','newC2N1','mp2env','newC1E2'
$nativeMp1=@(Get-Content "$oni\DLSS5-AMD\native-game-flags.txt")
try{foreach($side in $sides){
 $d="$root\runtime-$side";Remove-Item -Recurse -Force $d -EA 0;New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders"|Out-Null
 foreach($a in 'gfx1200','gfx1201'){Copy-Item "$oni\$hip\$a\*.hsaco" "$d\modules\$a" -Force}
 Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force
 Copy-Item $(if($side -like 'old*'){"$oni\LmxxfNrRuntime.dll"}else{"$lab\bin\LmxxfNrRuntime.dll"}) "$d\LmxxfNrRuntime.dll" -Force
 $c="$d\DLSS5-AMD"
 if($side -notin 'old','new','mp2env'){New-Item -ItemType Directory -Force $c|Out-Null}
 if($side -like 'new?*' -and $side -ne 'mp2env'){Copy-Item "$lab\bin\hip-re9-flags.txt" "$c\default-config.txt"}
 if($side -in 'oldN','newDN'){Copy-Item "$oni\DLSS5-AMD\native-game-flags.txt" "$c\native-game-flags.txt"}
 if($side -in 'newC2','newC2N1'){[IO.File]::WriteAllLines("$c\custom-config.txt",@('# test','DLSS5_MULTI_PASS=2'))}
 if($side -eq 'newC2N1'){Copy-Item "$oni\DLSS5-AMD\native-game-flags.txt" "$c\native-game-flags.txt"}
 if($side -eq 'newC1E2'){[IO.File]::WriteAllLines("$c\custom-config.txt",@('DLSS5_MULTI_PASS=1'))}
 $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring(("$d\modules\").Length).Replace('\','/'))"});[IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)}
if(!((Get-Content "$oni\DLSS5-AMD\native-game-flags.txt") -match '^DLSS5_MULTI_PASS=1$')){throw 'installed native file lacks DLSS5_MULTI_PASS=1'}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
foreach($height in 900,1080){foreach($side in $sides){foreach($rep in 'a','b'){
 $env:DLSS5_NETWORK_HEIGHT="$height";$d="$root\runtime-$side";$env:LMXXF_SHADER_DIR="$d\shaders"
 if($side -in 'mp2env','newC1E2'){$env:DLSS5_MULTI_PASS='2'}else{Remove-Item Env:\DLSS5_MULTI_PASS -EA 0}
 & 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$root\runtime-$side-$height-$rep.log"
 if($LASTEXITCODE){throw "rt_bench failed $side $height"}}}
 Remove-Item Env:\DLSS5_MULTI_PASS -EA 0
 $hx=@{};foreach($side in $sides){foreach($rep in 'a','b'){$hx["$side$rep"]=[regex]::Match((Get-Content "$root\runtime-$side-$height-$rep.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value}}
 $rr=@($sides|?{!$hx["${_}a"] -or $hx["${_}a"] -ne $hx["${_}b"]})
 function T($a,$b,$eq){if(($hx["${a}a"] -eq $hx["${b}a"]) -eq $eq){'OK'}else{'BAD'}}
 "RT $height old=$($hx.olda) new=$($hx.newa) [$(T 'old' 'new' $true)] oldN=$($hx.oldNa) newDN=$($hx.newDNa) [$(T 'oldN' 'newDN' $true)] newC2=$($hx.newC2a) mp2env=$($hx.mp2enva) [C2!=DN $(T 'newC2' 'newDN' $false)] newC2N1=$($hx.newC2N1a) [$(T 'newC2N1' 'newDN' $true)] newC1E2=$($hx.newC1E2a) [$(T 'newC1E2' 'newC2' $true)] | rerun $(if($rr.Count){'DIFF '+($rr -join ',')}else{'SAME'})"
 foreach($side in $sides){$f=Select-String -Path "$root\runtime-$side-$height-a.log" -Pattern 'flags:'|Select-Object -First 1;if($f){"  $side $($f.Line.Substring([Math]::Max(0,$f.Line.IndexOf('flags:'))))"}}}
$d="$root\runtime-new";$env:LMXXF_SHADER_DIR="$d\shaders"
& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" *> "$root\runtime-smoke.log"
"SMOKE exit=$LASTEXITCODE";Get-Content "$root\runtime-smoke.log" -Tail 2
} finally {if((Test-Path $L) -and ((Get-Content $L) -match 'config-layers-rt9')){Remove-Item $L -Force};'LOCK DROPPED'}

# rt.ps1: RE9 runtime. old = installed Onimusha runtime (73D4C25C), new = net-timing runtime; same installed modules.
# 1) rt_bench (re9-runtime-flags, built from the pre-change header = an old host passing LMXXF_NR_API_V1_SIZE) old/new 900/1080 hash SAME
# 2) rt_timing (new header) on new: ABI checks, per-frame GetTimings lag check, hash must equal 1); also 720 for the tier table
# 3) rt_bench ABBA old,new,new,old x3 at 900/1080, 400 frames (mean of last 3/4)  4) runtime-smoke on new
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\net-timing-20261002';$rt="$root\rt";$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
$bench='D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe'
foreach($side in 'old','new'){$d="$rt\runtime-$side";Remove-Item -Recurse -Force $d -EA 0;New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders"|Out-Null
 foreach($a in 'gfx1200','gfx1201'){Copy-Item "$oni\$hip\$a\*.hsaco" "$d\modules\$a" -Force}
 Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force
 Copy-Item $(if($side -eq 'old'){"$oni\LmxxfNrRuntime.dll"}else{"$root\bin\LmxxfNrRuntime.dll"}) "$d\LmxxfNrRuntime.dll" -Force
 $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring(("$d\modules\").Length).Replace('\','/'))"});[IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)
 "$side runtime $((Get-FileHash "$d\LmxxfNrRuntime.dll").Hash.Substring(0,8))"}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
function HashOf($f){[regex]::Match((Get-Content $f -Raw),'hash=([0-9a-f]+)').Groups[1].Value}
foreach($height in 900,1080){
 foreach($side in 'old','new'){$env:DLSS5_NETWORK_HEIGHT="$height";$d="$rt\runtime-$side";$env:LMXXF_SHADER_DIR="$d\shaders"
  & $bench "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$rt\bench-$side-$height.log";if($LASTEXITCODE){throw "rt_bench failed $side $height"}}
 $d="$rt\runtime-new";$env:LMXXF_SHADER_DIR="$d\shaders"
 & "$root\bin\rt_timing.exe" "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$rt\timing12-$height.log";$tc=$LASTEXITCODE
 $h=@((HashOf "$rt\bench-old-$height.log"),(HashOf "$rt\bench-new-$height.log"),(HashOf "$rt\timing12-$height.log"))
 "RUNTIME $height old=$($h[0]) new=$($h[1]) rt_timing=$($h[2]) exit=$tc $(if($h[0] -and $h[0] -eq $h[1] -and $h[0] -eq $h[2] -and !$tc){'SAME'}else{'MISMATCH'})"
 Select-String -Path "$rt\bench-new-$height.log" -Pattern 'status=' | %{ $_.Line.Substring(0,[Math]::Min(220,$_.Line.Length)) }}
foreach($height in 720,900,1080){$env:DLSS5_NETWORK_HEIGHT="$height";$d="$rt\runtime-new";$env:LMXXF_SHADER_DIR="$d\shaders"
 & "$root\bin\rt_timing.exe" "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 400 1 *> "$rt\timing400-$height.log";"TIMING $height exit=$LASTEXITCODE $((Select-String -Path "$rt\timing400-$height.log" -Pattern '^net_timing|^lag_mismatch|^abi:').Line -join ' | ')"}
foreach($round in 1..3){foreach($height in 900,1080){$m=@{}
 foreach($side in 'old','new','new','old'){$env:DLSS5_NETWORK_HEIGHT="$height";$d="$rt\runtime-$side";$env:LMXXF_SHADER_DIR="$d\shaders"
  $log="$rt\abba-$round-$height-$side.log";& $bench "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 400 1 *> $log;if($LASTEXITCODE){throw "abba failed"}
  $m[$side]+=@([double][regex]::Match((Get-Content $log -Raw),'mean_ms=([0-9.]+)').Groups[1].Value)}
 $o=($m['old']|Measure-Object -Average).Average;$n=($m['new']|Measure-Object -Average).Average
 "RT_ABBA round=$round $height old=$($o.ToString('F3')) new=$($n.ToString('F3')) delta=$(($n-$o).ToString('+0.000;-0.000'))"}}
$d="$rt\runtime-new";$env:LMXXF_SHADER_DIR="$d\shaders";Remove-Item Env:DLSS5_NETWORK_HEIGHT -EA 0
& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" *> "$rt\runtime-smoke.log"
"SMOKE exit=$LASTEXITCODE";Get-Content "$rt\runtime-smoke.log" -Tail 3
'RT_DONE'

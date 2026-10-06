# rt.ps1 (pdl-1080): RE9 runtime. old = main runtime (rt-old), new = candidate (rt-new); installed Onimusha modules; RE9 template env (PDL=1 SWIN_RUN=1).
# 1) 720/900/1080 old/new 12 frames: hash SAME + GetStatus pdl=<requested>/<dispatched>  2) ABBA old,new,new,old x3 at 900/1080, 400 frames  3) runtime-smoke on new
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\pdl-1080-20261002';$rt="$root\rt";$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
$bench='D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe'
foreach($side in 'old','new'){$d="$rt\runtime-$side";Remove-Item -Recurse -Force $d -EA 0;New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders"|Out-Null
 foreach($a in 'gfx1200','gfx1201'){Copy-Item "$oni\$hip\$a\*.hsaco" "$d\modules\$a" -Force}
 Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force
 Copy-Item "$root\bin\rt-$side\LmxxfNrRuntime.dll" "$d\LmxxfNrRuntime.dll" -Force
 $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring(("$d\modules\").Length).Replace('\','/'))"});[IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)
 "$side runtime $((Get-FileHash "$d\LmxxfNrRuntime.dll").Hash.Substring(0,8))"}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
function HashOf($f){[regex]::Match((Get-Content $f -Raw),'hash=([0-9a-f]+)').Groups[1].Value}
function PdlOf($f){[regex]::Match((Get-Content $f -Raw),'pdl=[0-9/]+').Value}
function Bench($side,$size,$frames,$log){$d="$rt\runtime-$side";$env:LMXXF_SHADER_DIR="$d\shaders";& $bench "$d\LmxxfNrRuntime.dll" "$d\modules" $size $frames 1 *> $log;$LASTEXITCODE}
foreach($height in 720,900,1080){$env:DLSS5_NETWORK_HEIGHT="$height"
 $e1=Bench old '1707x961' 12 "$rt\d-old-$height.log";$e2=Bench new '1707x961' 12 "$rt\d-new-$height.log"
 $h=@((HashOf "$rt\d-old-$height.log"),(HashOf "$rt\d-new-$height.log"))
 "RUNTIME $height old=$($h[0]) new=$($h[1]) exit=$e1/$e2 $(if($h[0] -and $h[0] -eq $h[1] -and !($e1+$e2)){'SAME'}else{'MISMATCH'}) status old $(PdlOf "$rt\d-old-$height.log") new $(PdlOf "$rt\d-new-$height.log")"}
foreach($round in 1..3){foreach($height in 900,1080){$m=@{};$env:DLSS5_NETWORK_HEIGHT="$height"
 foreach($side in 'old','new','new','old'){$log="$rt\abba-$round-$height-$side.log";if(Bench $side '1707x961' 400 $log){throw 'abba failed'}
  $m[$side]+=@([double][regex]::Match((Get-Content $log -Raw),'mean_ms=([0-9.]+)').Groups[1].Value)}
 $o=($m['old']|Measure-Object -Average).Average;$n=($m['new']|Measure-Object -Average).Average
 "RT_ABBA round=$round $height old=$($o.ToString('F3')) new=$($n.ToString('F3')) delta=$(($n-$o).ToString('+0.000;-0.000'))"}}
$d="$rt\runtime-new";$env:LMXXF_SHADER_DIR="$d\shaders";Remove-Item Env:DLSS5_NETWORK_HEIGHT -EA 0
& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" *> "$rt\runtime-smoke.log"
"SMOKE exit=$LASTEXITCODE";Get-Content "$rt\runtime-smoke.log" -Tail 3
'RT_DONE'

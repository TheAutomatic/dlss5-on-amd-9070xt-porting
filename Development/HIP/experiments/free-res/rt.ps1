# rt.ps1 (free-res): RE9 runtime. old = net-timing runtime (rt-old, 3103A0A7 = main), new = free-res runtime; installed Onimusha modules.
# 1) default (DLSS5_NETWORK_FREE_RES unset): old / new / new+new shaders, 900 and 1080, 12 frames, hash SAME
# 2) DLSS5_NETWORK_FREE_RES=1 on new (+ new shaders): 1707x961, 1920x1080 (must equal the 1080 tier on the same 1920x1080 input), 2560x1440, 3440x1440; twice each (repeatable)
# 3) ABBA old,new,new,old x3 at 900/1080 (default), 400 frames  4) runtime-smoke on new
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\free-res-20261002';$rt="$root\rt";$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
$bench='D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe'
foreach($side in 'old','new'){$d="$rt\runtime-$side";Remove-Item -Recurse -Force $d -EA 0;New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders","$d\shaders-new"|Out-Null
 foreach($a in 'gfx1200','gfx1201'){Copy-Item "$oni\$hip\$a\*.hsaco" "$d\modules\$a" -Force}
 Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force;Copy-Item "$d\shaders\*" "$d\shaders-new" -Force
 foreach($h in 'native_codec_encode','native_game_rgb_input'){Copy-Item "$root\bin\$h.hlsl" "$d\shaders-new\$h.hlsl" -Force}
 Copy-Item "$root\bin\rt-$side\LmxxfNrRuntime.dll" "$d\LmxxfNrRuntime.dll" -Force
 $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring(("$d\modules\").Length).Replace('\','/'))"});[IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)
 "$side runtime $((Get-FileHash "$d\LmxxfNrRuntime.dll").Hash.Substring(0,8))"}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
function HashOf($f){[regex]::Match((Get-Content $f -Raw),'hash=([0-9a-f]+)').Groups[1].Value}
function Bench($side,$sh,$size,$frames,$log){$d="$rt\runtime-$side";$env:LMXXF_SHADER_DIR="$d\$sh";& $bench "$d\LmxxfNrRuntime.dll" "$d\modules" $size $frames 1 *> $log;$LASTEXITCODE}
$ref=@{}
foreach($height in 900,1080){$env:DLSS5_NETWORK_HEIGHT="$height"
 $e1=Bench old shaders '1707x961' 12 "$rt\d-old-$height.log";$e2=Bench new shaders '1707x961' 12 "$rt\d-new-$height.log";$e3=Bench new shaders-new '1707x961' 12 "$rt\d-newsh-$height.log"
 $h=@((HashOf "$rt\d-old-$height.log"),(HashOf "$rt\d-new-$height.log"),(HashOf "$rt\d-newsh-$height.log"));$ref[$height]=$h[0]
 "RUNTIME $height old=$($h[0]) new=$($h[1]) new+shaders=$($h[2]) exit=$e1/$e2/$e3 $(if($h[0] -and $h[0] -eq $h[1] -and $h[0] -eq $h[2] -and !($e1+$e2+$e3)){'SAME'}else{'MISMATCH'})"}
$env:DLSS5_NETWORK_HEIGHT='1080';[void](Bench new shaders-new '1920x1080' 12 "$rt\t-1920x1080.log");$ref[1080]=HashOf "$rt\t-1920x1080.log" # tier reference on the same 1920x1080 input
Remove-Item Env:DLSS5_NETWORK_HEIGHT -EA 0;$env:DLSS5_NETWORK_FREE_RES='1'
foreach($size in '1707x961','1920x1080','2560x1440','3440x1440'){$a=Bench new shaders-new $size 12 "$rt\f-$size-a.log";$b=Bench new shaders-new $size 12 "$rt\f-$size-b.log"
 $ha=HashOf "$rt\f-$size-a.log";$hb=HashOf "$rt\f-$size-b.log";$geo=(Select-String -Path "$rt\f-$size-a.log" -Pattern 'proc \d+x\d+' | Select -First 1 | %{$_.Matches[0].Value})
 "FREE $size exit=$a/$b hash=$ha repeat=$(if($ha -and $ha -eq $hb){'SAME'}else{'DIFF '+$hb}) $geo $(if($size -eq '1920x1080'){'vs1080 '+$(if($ha -eq $ref[1080]){'SAME'}else{'DIFF'})})"}
Remove-Item Env:DLSS5_NETWORK_FREE_RES -EA 0
foreach($round in 1..3){foreach($height in 900,1080){$m=@{};$env:DLSS5_NETWORK_HEIGHT="$height"
 foreach($side in 'old','new','new','old'){$log="$rt\abba-$round-$height-$side.log";if(Bench $side shaders '1707x961' 400 $log){throw 'abba failed'}
  $m[$side]+=@([double][regex]::Match((Get-Content $log -Raw),'mean_ms=([0-9.]+)').Groups[1].Value)}
 $o=($m['old']|Measure-Object -Average).Average;$n=($m['new']|Measure-Object -Average).Average
 "RT_ABBA round=$round $height old=$($o.ToString('F3')) new=$($n.ToString('F3')) delta=$(($n-$o).ToString('+0.000;-0.000'))"}}
$d="$rt\runtime-new";$env:LMXXF_SHADER_DIR="$d\shaders";Remove-Item Env:DLSS5_NETWORK_HEIGHT -EA 0
& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" *> "$rt\runtime-smoke.log"
"SMOKE exit=$LASTEXITCODE";Get-Content "$rt\runtime-smoke.log" -Tail 3
'RT_DONE'

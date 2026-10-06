# rt.ps1 (outside-net): RE9 runtime candidates. base = main a4c84272 (A9BA5502), D = direct input (DLSS5_DIRECT_IO bit 1, default on),
# DQ = D + DLSS5_HIP_POST_SIGNAL_QUERY=1 (hipStreamQuery after the output signal). D with DLSS5_DIRECT_IO=0 must behave as base.
# 1) hashes: rt_bench 1707x961 x 720/900/1080 (12 frames) and rt_outside 1600x900,1920x1080 (auto tier)  2) ABBA serial (rt_bench
# mean_ms, wall per frame incl. CPU wait) and pipelined (rt_outside OUT_PIPE=1, median frame interval), base,cand,cand,base x3  3) smoke
param([string[]]$Cands=@('D','DQ'),[int]$Rounds=3)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\outside-net-20261002';$rt="$root\rt";$bench='D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe'
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
function Busy{if(Get-Process -EA 0|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){throw 'GAME RUNNING'}}
function HashOf($f){@([regex]::Matches((Get-Content $f -Raw),'hash=([0-9a-f]+)')|%{$_.Groups[1].Value}) -join ','}
function Side($s){$script:dio=$null;if($s -eq 'D0'){$s='D';$script:dio='0'};if($script:dio){$env:DLSS5_DIRECT_IO=$script:dio}else{Remove-Item Env:DLSS5_DIRECT_IO -EA 0};$d="$rt\runtime-$s";$env:LMXXF_SHADER_DIR="$d\shaders";$d}
function Bench($side,$size,$frames,$log){Busy;$d=Side $side;& $bench "$d\LmxxfNrRuntime.dll" "$d\modules" $size $frames 1 *> $log;$LASTEXITCODE}
function Pipe($side,$log){Busy;$d=Side $side;$env:OUT_PIPE='1';$env:OUT_TIMING='0';& "$root\rt_outside.exe" "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 400 1 *> $log;$e=$LASTEXITCODE;Remove-Item Env:OUT_PIPE,Env:OUT_TIMING -EA 0;if($e){throw "pipe failed $side"}
 [double][regex]::Match((Get-Content $log -Raw),'wall med=([0-9.]+)').Groups[1].Value}
$all=@('base')+$Cands+@('D0')
foreach($height in 720,900,1080){$env:DLSS5_NETWORK_HEIGHT="$height";$hs=@{}
 foreach($s in $all){$e=Bench $s '1707x961' 12 "$rt\h-$s-$height.log";$hs[$s]="$(HashOf "$rt\h-$s-$height.log")/e$e"}
 "HASH $height $(($all|%{"$_=$($hs[$_])"}) -join ' ') $(if(@($all|%{$hs[$_]}|Select-Object -Unique).Count -eq 1 -and $hs['base'] -match '^[0-9a-f]+/e0$'){'SAME'}else{'MISMATCH'})"}
Remove-Item Env:DLSS5_NETWORK_HEIGHT -EA 0;$hs=@{}
foreach($s in $all){Busy;$d=Side $s;$env:OUT_TIMING='0';& "$root\rt_outside.exe" "$d\LmxxfNrRuntime.dll" "$d\modules" '1600x900,1920x1080' 12 1 *> "$rt\o-$s.log";$hs[$s]="$(HashOf "$rt\o-$s.log")/e$LASTEXITCODE";Remove-Item Env:OUT_TIMING}
"HASH native $(($all|%{"$_=$($hs[$_])"}) -join ' ') $(if(@($all|%{$hs[$_]}|Select-Object -Unique).Count -eq 1){'SAME'}else{'MISMATCH'})"
foreach($c in $Cands){foreach($round in 1..$Rounds){foreach($height in 900,1080){$env:DLSS5_NETWORK_HEIGHT="$height";$m=@{};$p=@{}
 foreach($side in 'base',$c,$c,'base'){$log="$rt\abba-$c-$round-$height-$side.log";if(Bench $side '1707x961' 400 $log){throw 'abba failed'}
  $m[$side]+=@([double][regex]::Match((Get-Content $log -Raw),'mean_ms=([0-9.]+)').Groups[1].Value)}
 foreach($side in 'base',$c,$c,'base'){$p[$side]+=@(Pipe $side "$rt\pipe-$c-$round-$height-$side.log")}
 $o=($m['base']|Measure-Object -Average).Average;$n=($m[$c]|Measure-Object -Average).Average;$po=($p['base']|Measure-Object -Average).Average;$pn=($p[$c]|Measure-Object -Average).Average
 "RT_ABBA $c round=$round $height serial $($o.ToString('F3'))->$($n.ToString('F3')) ($(($n-$o).ToString('+0.000;-0.000')))  pipe $($po.ToString('F3'))->$($pn.ToString('F3')) ($(($pn-$po).ToString('+0.000;-0.000')))"}}}
Remove-Item Env:DLSS5_NETWORK_HEIGHT -EA 0
foreach($c in $Cands){$d=Side $c;& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" *> "$rt\smoke-$c.log";"SMOKE $c exit=$LASTEXITCODE $((Get-Content "$rt\smoke-$c.log" -Tail 2) -join ' | ')"}
'RT_DONE'

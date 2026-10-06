# ngx.ps1 (fast-numeric): fidelity-ngx single frame 1920x1080, Style 0, against NVIDIA. bench_ngx = benchmark_live_capture (branch host) with
# BENCH_W/BENCH_H; modules = flat-F (installed + -fast). Runs: FAST_NUMERIC 0/1 x release skip 42,43,46 / all 71 blocks; also 1088 rows with =1.
$ErrorActionPreference='Stop';$lab='D:\DLSSNR-Lab\hip-backend\fast-numeric-20261003';$w="$lab\ngx";$L='D:\DLSSNR-Lab\gpu.lock'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64|^benchmark'}){'GPU BUSY';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"fast-numeric-ngx $(Get-Date -Format s)"|Out-File -Encoding ascii $L
try{New-Item -ItemType Directory -Force $w|Out-Null;Copy-Item 'D:\DLSSNR-Lab\hip-backend\rebuild-baseline-20261001\ngx\in-1920x1080.f16' $w -Force
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD'
$drop='^(DLSS5_PRE_UPSCALE|DLSS5_SHOW_FPS|DLSS5_NETWORK_HEIGHT|DLSS5_FRAME_STATS|DLSS5_VIT_ADAPTIVE|DLSS5_VIT_REUSE_HOTKEY|DLSS5_SKIP_BLOCKS|DLSS5_OUTPUT_SMOOTH|DLSS5_STRENGTH|DLSS5_CODEC_SRGB|DLSS5_DIRECT_IO|DLSS5_FIT_INPUT|DLSS5_FIT_LARGE|DLSS5_HOT_RELOAD|DLSS5_STYLE|DLSS5_FAST_NUMERIC|DLSS5_NETWORK_1080_ROWS)='
foreach($run in @(@{t='fn0-rel';fn='0';skip='42,43,46';rows=''},@{t='fn1-rel';fn='1';skip='42,43,46';rows=''},@{t='fn0-full';fn='0';skip='none';rows=''},@{t='fn1-full';fn='1';skip='none';rows=''},@{t='fn1-full-1088';fn='1';skip='none';rows='1088'},@{t='fn0-full-1088';fn='0';skip='none';rows='1088'})){
 $out="$w\out-$($run.t)";New-Item -ItemType Directory -Force $out|Out-Null;Get-ChildItem $out -Filter *.f16|Remove-Item -Force
 $flags=@(Get-Content "$g\native-game-flags.txt"|?{$_ -notmatch $drop})+@('DLSS5_PRE_UPSCALE=0','DLSS5_SHOW_FPS=0','DLSS5_NETWORK_HEIGHT=1080','DLSS5_VIT_ADAPTIVE=0','DLSS5_STRENGTH=1,1','DLSS5_CODEC_SRGB=1','DLSS5_FIT_INPUT=1','DLSS5_FIT_LARGE=1','DLSS5_HOT_RELOAD=0','DLSS5_RESIDUAL_RGB=0','DLSS5_STYLE=0',"DLSS5_FAST_NUMERIC=$($run.fn)")
 if($run.skip -ne 'none'){$flags+="DLSS5_SKIP_BLOCKS=$($run.skip)"}else{$flags+='DLSS5_SKIP_BLOCKS='};if($run.rows){$flags+="DLSS5_NETWORK_1080_ROWS=$($run.rows)"}
 [IO.File]::WriteAllLines("$out\flags.txt",$flags);$env:BENCH_W='1920';$env:BENCH_H='1080'
 $ErrorActionPreference='Continue';& "$lab\bin\bench_ngx.exe" "$g\native-game-tiled-assets" "$out\flags.txt" "$w\in-1920x1080.f16" "$out\o" 1 0 "$lab\flat-F" 0 0 0 0 > "$out\run.log" 2> "$out\stderr.log";$ec=$LASTEXITCODE;$ErrorActionPreference='Stop'
 "$($run.t) exit=$ec $((Get-ChildItem $out -Filter *.f16|%{"$($_.Name) $((Get-FileHash $_.FullName).Hash.Substring(0,8))"}) -join ' ')"}
} finally {if((Test-Path $L) -and ((Get-Content $L) -match 'fast-numeric-ngx')){Remove-Item $L -Force};'LOCK DROPPED'}

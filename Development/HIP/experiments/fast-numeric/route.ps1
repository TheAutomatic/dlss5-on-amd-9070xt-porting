# route.ps1 (fast-numeric): which files the host opens. flat-X = flat-A + junk c32-wave1-fast/c64-wave2-fast.
# base and F with the option unset or 0 must run every tier on flat-X (never open -fast); F with =1 must fail on flat-X at every tier;
# flat-Y = flat-F with a junk c32-wave1-fast only: F with =1 must fail on that file at every tier (1080 too: fast C32 replaces the rtz build).
# F with =1 on flat-A (no -fast files) must run, log the fallback line and give the same output as base.
$root='D:\DLSSNR-Lab\hip-backend\fast-numeric-20261003';$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD';$L='D:\DLSSNR-Lab\gpu.lock'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"fast-numeric-route $(Get-Date -Format s)"|Out-File -Encoding ascii $L
try{Remove-Item "$root\flat-Y" -Recurse -Force -EA 0;Copy-Item "$root\flat-F" "$root\flat-Y" -Recurse;[IO.File]::WriteAllBytes("$root\flat-Y\c32-wave1-fast.hsaco",[byte[]](1..64))
 foreach($cfg in @(@{h=720;rows=''},@{h=900;rows=''},@{h=1080;rows=''},@{h=1080;rows='1088'})){
 foreach($run in @(@{exe='base';set='X';fn=''},@{exe='F';set='X';fn='0'},@{exe='F';set='X';fn='1'},@{exe='F';set='Y';fn='1'},@{exe='F';set='A';fn='1'},@{exe='base';set='A';fn=''})){
 $n="route-$($run.exe)-$($run.set)-fn$($run.fn)-$($cfg.h)$($cfg.rows)"
 $flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$($cfg.h)",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_VIT_ADAPTIVE_IDLE_MS=1000000000')
 if($cfg.rows){$flags+="DLSS5_NETWORK_1080_ROWS=$($cfg.rows)"};if($run.fn){$flags+="DLSS5_FAST_NUMERIC=$($run.fn)"}
 $ft="$root\$n-flags.txt";[IO.File]::WriteAllLines($ft,$flags)
 $ErrorActionPreference='Continue';& "$root\benchmark-$($run.exe).exe" "$root\assets-base" $ft "$r\live-menu-before.f16" "$root\$n" 20 0 "$root\flat-$($run.set)" 0 1 0 0 > "$root\$n.log" 2> "$root\$n.err";$ec=$LASTEXITCODE
 $e=(Get-Content "$root\$n.err" -EA 0|Select-String 'FAST_NUMERIC|hsaco|rror'|Select-Object -First 1)
 $h=if(Test-Path "$root\$n.f16"){(Get-FileHash "$root\$n.f16").Hash.Substring(0,8)}else{'-'}
 "ROUTE $n exit=$ec out=$h $e"
 Get-ChildItem $root -Filter "$n*" -Include *.f16,*.ppm -EA 0|Remove-Item -Force -EA 0}}
} finally {Get-ChildItem $root -Filter *.f16 -EA 0|Remove-Item -Force -EA 0;if((Test-Path $L) -and ((Get-Content $L) -match 'fast-numeric-route')){Remove-Item $L -Force};'LOCK DROPPED'}
'ROUTE_DONE'

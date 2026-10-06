# route.ps1 (rtz1080): which c32 file each tier loads. flat-X = flat-A + a junk c32-wave1-rtz.hsaco; benchmark-T must run 900/720
# (never opens it) and fail at 1080 (1152 and 1088 rows: loads it). benchmark-base on flat-X runs everywhere (never opens it).
$root='D:\DLSSNR-Lab\hip-backend\rtz1080-20261003';$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD';$L='D:\DLSSNR-Lab\gpu.lock'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"rtz1080-route $(Get-Date -Format s)"|Out-File -Encoding ascii $L
try{Remove-Item "$root\flat-X" -Recurse -Force -EA 0;Copy-Item "$root\flat-A" "$root\flat-X" -Recurse;[IO.File]::WriteAllBytes("$root\flat-X\c32-wave1-rtz.hsaco",[byte[]](1..64))
foreach($cfg in @(@{h=720;rows=''},@{h=900;rows=''},@{h=1080;rows=''},@{h=1080;rows='1088'})){foreach($exe in 'base','T'){$n="route-$exe-$($cfg.h)$($cfg.rows)"
 $flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$($cfg.h)",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_VIT_ADAPTIVE_IDLE_MS=1000000000')
 if($cfg.rows){$flags+="DLSS5_NETWORK_1080_ROWS=$($cfg.rows)"}
 $ft="$root\$n-flags.txt";[IO.File]::WriteAllLines($ft,$flags)
 $ErrorActionPreference='Continue';& "$root\benchmark-$exe.exe" "$root\assets-base" $ft "$r\live-menu-before.f16" "$root\$n" 20 0 "$root\flat-X" 0 1 0 0 > "$root\$n.log" 2> "$root\$n.err";$ec=$LASTEXITCODE
 $e=(Get-Content "$root\$n.err" -EA 0|Select-String 'c32-wave1|module|error' -SimpleMatch:$false|Select-Object -First 1)
 "ROUTE $exe h=$($cfg.h) rows=$($cfg.rows) exit=$ec $e"
 Get-ChildItem $root -Filter "$n*" -Include *.f16,*.ppm -EA 0|Remove-Item -Force -EA 0}}
} finally {Get-ChildItem $root -Filter *.f16 -EA 0|Remove-Item -Force -EA 0;if((Test-Path $L) -and ((Get-Content $L) -match 'rtz1080-route')){Remove-Item $L -Force};'LOCK DROPPED'}
'ROUTE_DONE'

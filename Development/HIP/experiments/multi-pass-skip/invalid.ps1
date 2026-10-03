# invalid.ps1 (multi-pass-skip, called by go.ps1 under its lock): host M, 900 tier, 20 frames;
# DLSS5_MULTI_PASS=3 with DLSS5_MULTI_PASS_SKIP_BLOCKS unset / empty / abc / 99 / 10 (C64 block, not skippable with the byte stream)
# must give the same hash (= 3 passes, no extra skip); the invalid ones print a stderr line. 42,43,46 must differ. Native stderr is captured with ErrorActionPreference Continue.
$root='D:\DLSSNR-Lab\hip-backend\multi-pass-skip-20261003';$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD';$ErrorActionPreference='Continue'
$base=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0','DLSS5_NETWORK_HEIGHT=900','DLSS5_VIT_ADAPTIVE=0','DLSS5_RESIDUAL_SEQUENCE=1','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1')
$ref=$null
foreach($run in @(@{exe='M';v=$null},@{exe='M';v=''},@{exe='M';v='abc'},@{exe='M';v='99'},@{exe='M';v='10'},@{exe='M';v='42,43,46'})){
 $n="inv-$(if($run.v -eq $null){'unset'}elseif($run.v -eq ''){'empty'}else{$run.v.Replace(',','_')})";$f=$base+@('DLSS5_SKIP_BLOCKS=','DLSS5_FAST_NUMERIC=1','DLSS5_MULTI_PASS=3');if($run.v -ne $null){$f+="DLSS5_MULTI_PASS_SKIP_BLOCKS=$($run.v)"};$ft="$root\$n-flags.txt";[IO.File]::WriteAllLines($ft,$f)
 & "$root\benchmark-$($run.exe).exe" "$root\assets-base" $ft "$r\live-menu-before.f16" "$root\$n" 20 0 "$root\flat-M" 0 1 0 0 > "$root\$n.log" 2> "$root\$n.err";$ec=$LASTEXITCODE
 $h=(Get-FileHash "$root\$n.f16").Hash.Substring(0,8);if(!$ref){$ref=$h};$e=(Get-Content "$root\$n.err" -EA 0|Select-String 'MULTI_PASS_SKIP'|Select-Object -First 1)
 "INVALID $n exit=$ec out=$h $(if($h -eq $ref){'SAME'}else{'DIFF'}) $e";Remove-Item "$root\$n.f16","$root\$n*.ppm" -Force -EA 0}

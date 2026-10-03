# export.ps1 (multi-pass-extrap, offline, called under gpu.lock by run.sh): host benchmark-M (DLSS5_MULTI_PASS branch), flat-M modules,
# same flags as multi-pass-20261003 regression.ps1 (RESIDUAL_RGB=1, 12 frames, adaptive 0). Per case, runs:
#  x   = STRENGTH 0,0 (decoder returns the game colour unchanged)  | p1/p2/p3 = MULTI_PASS 1/2/3, STRENGTH 1,1
#  s2/s25/s3 = MULTI_PASS 1 with STRENGTH k,k (the decoder's own lerp past the network, k=2/2.5/3).
# Keeps frame 11 (rgb-frame-11.f16, 1296x720 RGBA16F, linear, final pipeline output) per run in out\, deletes the rest.
$ErrorActionPreference='Stop';$mp='D:\DLSSNR-Lab\hip-backend\multi-pass-20261003';$root='D:\DLSSNR-Lab\hip-backend\multi-pass-extrap-20261003';$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
New-Item -ItemType Directory -Force "$root\out"|Out-Null
$runs=@(@{n='x';p='1';s='0,0'},@{n='p1';p='1';s='1,1'},@{n='p2';p='2';s='1,1'},@{n='p3';p='3';s='1,1'},@{n='s2';p='1';s='2,2'},@{n='s25';p='1';s='2.5,2.5'},@{n='s3';p='1';s='3,3'})
foreach($case in @(@{n='900-static';h=900;s=0;t=0},@{n='1080-static';h=1080;s=0;t=0},@{n='1080-motion';h=1080;s=1;t=0},@{n='1080-history';h=1080;s=5;t=1})){
 foreach($run in $runs){$tag="$($case.n)-$($run.n)";$dir="$root\work\$tag";New-Item -ItemType Directory -Force $dir|Out-Null
  $f=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$($case.h)",'DLSS5_VIT_ADAPTIVE=0',"DLSS5_RESIDUAL_SEQUENCE=$($case.s)",'DLSS5_RESIDUAL_RGB=1','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_VIT_ADAPTIVE_IDLE_MS=1000000000','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_HOT_RELOAD=0',"DLSS5_MULTI_PASS=$($run.p)","DLSS5_STRENGTH=$($run.s)")
  [IO.File]::WriteAllLines("$dir\flags.txt",$f)
  & "$mp\benchmark-M.exe" "$mp\assets-base" "$dir\flags.txt" "$r\live-menu-before.f16" "$dir\rgb" 12 $case.t "$mp\flat-M" 0 0 0 0 > "$dir\run.log" 2> "$dir\run.err"
  if($LASTEXITCODE){throw "run failed $tag"}
  Copy-Item "$dir\rgb-frame-11.f16" "$root\out\$tag.f16" -Force;"RUN $tag $((Get-FileHash "$root\out\$tag.f16").Hash.Substring(0,8))"
  Get-ChildItem $dir -Include *.f16,*.ppm -Recurse|Remove-Item -Force}}
'EXPORT_DONE'

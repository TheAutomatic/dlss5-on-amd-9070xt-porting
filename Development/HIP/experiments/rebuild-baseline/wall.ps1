# wall.ps1: whole-net single frame (gap-map-evening method): installed state = benchmark-base (e22d15a2 = installed add-on source) + flat-A;
# also HEAD (benchmark-H + flat-H). 900 / 1080x1152 / 1080x1088, two passes, 1000 frames, drop 200; span = DLSS5_HIP_SPAN_PROBE median.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\rebuild-baseline-20261001';$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall'}){throw 'game running'}
function Med($v){if(!$v.Count){return 'na'};$s=$v|Sort-Object;$s[[int]($s.Count/2)]}
function Flags($h,$rows){@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$h",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_HIP_SPAN_PROBE=1','DLSS5_VIT_ADAPTIVE_IDLE_MS=1000000000',"DLSS5_NETWORK_1080_ROWS=$rows")}
$env:DLSS5_HIP_SPAN_PROBE='1';New-Item -ItemType Directory -Force "$root\wall"|Out-Null
foreach($pass in 1,2){foreach($side in @(@('inst','benchmark-base.exe','flat-A'),@('head','benchmark-H.exe','flat-H'))){foreach($c in @(@(900,1152),@(1080,1152),@(1080,1088))){
 $n="$($side[0])-$($c[0])-$($c[1])-$pass";$ft="$root\wall\$n-flags.txt";[IO.File]::WriteAllLines($ft,(Flags $c[0] $c[1]))
 $ErrorActionPreference='Continue';& "$root\$($side[1])" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' $ft "$r\live-menu-before.f16" "$root\wall\$n" 1000 0 "$root\$($side[2])" 0 1 0 0 > "$root\wall\$n.log" 2> "$root\wall\$n.err";$ec=$LASTEXITCODE;$ErrorActionPreference='Stop'
 $w=@(Import-Csv "$root\wall\$n.csv"|?{[int]$_.frame -ge 200}|%{[double]$_.wall_ms})
 $sp=@(Select-String -Path "$root\wall\$n.err" -Pattern 'hip_span gpu_ms=([0-9.]+)'|%{[double]$_.Matches[0].Groups[1].Value});if($sp.Count -gt 200){$sp=$sp[200..($sp.Count-1)]}
 "$n exit=$ec wall_mean=$(($w|Measure-Object -Average).Average) wall_med=$(Med $w) span_med=$(Med $sp)"|Tee-Object -Append "$root\wall.txt"}}}
Get-ChildItem "$root\wall" -Include *.f16,*.ppm -Recurse|Remove-Item -Force
'WALL_DONE'

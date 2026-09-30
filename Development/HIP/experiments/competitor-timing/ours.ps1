param([int]$Height=900,[string]$Tag='wall',[int]$Frames=1000,[int]$Span=0,[int]$Rows=1152)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\competitor-timing-20260930\ours';$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^recorder|^jobbench|^Magpie|^evprof|^bw|^nr_graph'}){throw 'GPU busy'}
$flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$Height",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60',"DLSS5_NETWORK_1080_ROWS=$Rows")
if($Span){$flags+='DLSS5_HIP_SPAN_PROBE=1';$env:DLSS5_HIP_SPAN_PROBE='1'}else{Remove-Item Env:DLSS5_HIP_SPAN_PROBE -ErrorAction SilentlyContinue}
$n="$Tag-$Height-$Rows";$ft="$root\$n-flags.txt";[IO.File]::WriteAllLines($ft,$flags)
$ErrorActionPreference="Continue";& "$root\benchmark-P.exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' $ft "$r\live-menu-before.f16" "$root\$n" $Frames 0 "$root\flat" 0 1 0 0 > "$root\$n.log" 2> "$root\$n.err"
$ec=$LASTEXITCODE
$rows_=@(Import-Csv "$root\$n.csv");$skip=200;$w=@($rows_|Where-Object{[int]$_.frame -ge $skip}|ForEach-Object{[double]$_.wall_ms})
$sp=@(Select-String -Path "$root\$n.err" -Pattern 'hip_span gpu_ms=([0-9.]+)' | ForEach-Object {[double]$_.Matches[0].Groups[1].Value});if($sp.Count -gt $skip){$sp=$sp[$skip..($sp.Count-1)]}
function Med($v){if(!$v.Count){return 'na'};$s=$v|Sort-Object;$s[[int]($s.Count/2)]}
"$n exit=$ec wall_mean=$(($w|Measure-Object -Average).Average) wall_med=$(Med $w) span_n=$($sp.Count) span_mean=$(if($sp.Count){($sp|Measure-Object -Average).Average}) span_med=$(Med $sp)"

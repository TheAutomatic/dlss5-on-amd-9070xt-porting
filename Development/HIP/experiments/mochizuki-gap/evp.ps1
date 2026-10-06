param([int]$Height=900,[string]$Exe='benchmark-base.exe',[string]$Tag='wall',[int]$Frames=1000,[int]$Span=0,[int]$Profile=0,[string]$Mods='flat-C')
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\mochizuki-gap-20261001\evp';$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^recorder|^jobbench|^Magpie|^evprof|^bw'}){throw 'GPU busy'}
$flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$Height",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60')
if($Profile){$flags+='DLSS5_MAP_PROFILE=1';$env:DLSS5_MAP_PROFILE='1'}else{Remove-Item Env:DLSS5_MAP_PROFILE -ErrorAction SilentlyContinue}
if($Span){$flags+='DLSS5_HIP_SPAN_PROBE=1';$env:DLSS5_HIP_SPAN_PROBE='1'}else{Remove-Item Env:DLSS5_HIP_SPAN_PROBE -ErrorAction SilentlyContinue}
$ft="$root\$Tag-flags-$Height.txt";[IO.File]::WriteAllLines($ft,$flags)
$ErrorActionPreference="Continue";& "$root\$Exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' $ft "$r\live-menu-before.f16" "$root\$Tag-$Height" $Frames 0 "$root\$Mods" 0 1 0 0 > "$root\$Tag-$Height.log" 2> "$root\$Tag-$Height.err"
$ec=$LASTEXITCODE
$rows=@(Import-Csv "$root\$Tag-$Height.csv");$skip=[math]::Min(200,[int]($Frames/5));$w=@($rows|Where-Object{[int]$_.frame -ge $skip}|ForEach-Object{[double]$_.wall_ms})
$sp=@(Select-String -Path "$root\$Tag-$Height.err" -Pattern 'hip_span gpu_ms=([0-9.]+)' | ForEach-Object {[double]$_.Matches[0].Groups[1].Value});if($sp.Count -gt $skip){$sp=$sp[$skip..($sp.Count-1)]}
function Med($v){if(!$v.Count){return 'na'};$s=$v|Sort-Object;$s[[int]($s.Count/2)]}
"$Tag h=$Height exit=$ec wall_mean=$(($w|Measure-Object -Average).Average) wall_med=$(Med $w) span_n=$($sp.Count) span_mean=$(if($sp.Count){($sp|Measure-Object -Average).Average}) span_med=$(Med $sp) kev=$(@(Select-String -Path "$root\$Tag-$Height.log" -Pattern '^KEV,').Count)"

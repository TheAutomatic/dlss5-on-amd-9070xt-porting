# One bench_ngx run (full NativeGameFrame: encode -> HIP network -> decode) on in\in-<Res>.f16 (RGBA16F, sRGB-encoded 0..1).
# Flags = installed Stellar Blade flags minus per-run keys, + single-frame reset contract of fidelity-ngx (STRENGTH 1,1, CODEC_SRGB 1, smooth off).
param([string]$Exe='ngx-F.exe',[string]$Assets='assets-cand',[string]$Res='1920x1080',[int]$Free=0,[string]$Style='1',[string]$Skip='42,43,46',[int]$Frames=1,[string]$Tag='a',[int]$Span=0,[string[]]$Extra=@(),[int]$Keep=1)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\free-res-20261002'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD'
$out="$root\out\$Tag-$Res";New-Item -ItemType Directory -Force $out|Out-Null
$drop='^(DLSS5_PRE_UPSCALE|DLSS5_SHOW_FPS|DLSS5_NETWORK_HEIGHT|DLSS5_FRAME_STATS|DLSS5_VIT_ADAPTIVE|DLSS5_VIT_REUSE_HOTKEY|DLSS5_SKIP_BLOCKS|DLSS5_OUTPUT_SMOOTH|DLSS5_STRENGTH|DLSS5_CODEC_SRGB|DLSS5_FIT_INPUT|DLSS5_FIT_LARGE|DLSS5_HOT_RELOAD|DLSS5_STYLE|DLSS5_NETWORK_FREE_RES)='
$flags=@(Get-Content "$g\native-game-flags.txt" | ? {$_ -notmatch $drop})+@('DLSS5_PRE_UPSCALE=0','DLSS5_SHOW_FPS=0','DLSS5_NETWORK_HEIGHT=auto','DLSS5_VIT_ADAPTIVE=0','DLSS5_STRENGTH=1,1','DLSS5_CODEC_SRGB=1','DLSS5_FIT_INPUT=1','DLSS5_FIT_LARGE=1','DLSS5_HOT_RELOAD=0','DLSS5_RESIDUAL_RGB=0',"DLSS5_STYLE=$Style","DLSS5_HIP_SPAN_PROBE=$Span")
if($Free){$flags+='DLSS5_NETWORK_FREE_RES=1'}
if($Skip -ne 'none'){$flags+="DLSS5_SKIP_BLOCKS=$Skip"}
$flags+=$Extra
[IO.File]::WriteAllLines("$out\flags.txt",$flags)
$wh=$Res.Split('x');$env:BENCH_W=$wh[0];$env:BENCH_H=$wh[1]
$ErrorActionPreference='Continue'
& "$root\$Exe" "$root\$Assets" "$out\flags.txt" "$root\in\in-$Res.f16" "$out\o" $Frames 0 "$root\flat-A" 0 0 0 0 > "$out\run.log" 2> "$out\stderr.log"
$code=$LASTEXITCODE;$ErrorActionPreference='Stop'
$sp=@(Select-String -Path "$out\stderr.log" -Pattern 'hip_span gpu_ms=([0-9.]+)' | % {[double]$_.Matches[0].Groups[1].Value})
$spm=if($sp.Count -gt 2){$s=$sp|Select-Object -Skip 2|Sort-Object;$s[[int][math]::Floor($s.Count/2)]}else{-1}
$wall=-1;if(Test-Path "$out\o.csv"){$w=@(Import-Csv "$out\o.csv"|?{[int]$_.frame -ge 2}|%{[double]$_.wall_ms}|Sort-Object);if($w.Count){$wall=[math]::Round($w[[int][math]::Floor($w.Count/2)],3)}}
$geo=(Select-String -Path "$out\run.log","$out\stderr.log" -Pattern 'network=\S+' | Select-Object -First 1 | % {$_.Line})
$sha=if(Test-Path "$out\o.f16"){(Get-FileHash "$out\o.f16").Hash.Substring(0,16)}else{'none'}
"RUN tag=$Tag res=$Res free=$Free style=$Style skip=$Skip exit=$code wall_med=$wall span_med=$spm n_span=$($sp.Count) sha=$sha"
if($code){Get-Content "$out\stderr.log" | Select-Object -Last 5}
if($geo){"  $geo"}
if(!$Keep){Remove-Item "$out\o.ppm" -EA 0}

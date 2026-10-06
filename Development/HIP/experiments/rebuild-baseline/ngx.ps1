# ngx.ps1: fidelity-ngx run.ps1 with DLSS5_STYLE; modules = build-style\gfx1201; 1080p single frame, Skip '42,43,46' (release) or 'none' (full 71)
param([string]$Style='0',[string]$Skip='42,43,46',[string]$Tag='s0')
$ErrorActionPreference='Stop'
if(Get-Process -ErrorAction SilentlyContinue | ? {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark$|^Magpie'}){throw 'GPU busy'}
$root='D:\DLSSNR-Lab\hip-backend\rebuild-baseline-20261001';$w="$root\ngx";$Res='1920x1080'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD'
$out="$w\out-$Tag";New-Item -ItemType Directory -Force $out|Out-Null
$drop='^(DLSS5_PRE_UPSCALE|DLSS5_SHOW_FPS|DLSS5_NETWORK_HEIGHT|DLSS5_FRAME_STATS|DLSS5_VIT_ADAPTIVE|DLSS5_VIT_REUSE_HOTKEY|DLSS5_SKIP_BLOCKS|DLSS5_OUTPUT_SMOOTH|DLSS5_STRENGTH|DLSS5_CODEC_SRGB|DLSS5_DIRECT_IO|DLSS5_FIT_INPUT|DLSS5_FIT_LARGE|DLSS5_HOT_RELOAD|DLSS5_STYLE)='
$flags=@(Get-Content "$g\native-game-flags.txt" | ? {$_ -notmatch $drop})+@('DLSS5_PRE_UPSCALE=0','DLSS5_SHOW_FPS=0',"DLSS5_NETWORK_HEIGHT=1080","DLSS5_VIT_ADAPTIVE=0",'DLSS5_STRENGTH=1,1',"DLSS5_CODEC_SRGB=1",'DLSS5_FIT_INPUT=1','DLSS5_FIT_LARGE=1','DLSS5_HOT_RELOAD=0','DLSS5_RESIDUAL_RGB=0')
if($Style -ne 'unset'){$flags+="DLSS5_STYLE=$Style"}
if($Skip -ne "none"){$flags+="DLSS5_SKIP_BLOCKS=$Skip"}
[IO.File]::WriteAllLines("$out\flags.txt",$flags)
$env:BENCH_W='1920';$env:BENCH_H='1080'
$ErrorActionPreference='Continue'
& "$w\bench_ngx.exe" "$g\native-game-tiled-assets" "$out\flags.txt" "$w\in-$Res.f16" "$out\o" 1 0 "$root\build-style\gfx1201" 0 0 0 0 > "$out\run.log" 2> "$out\stderr.log"
"$Tag exit=$LASTEXITCODE"; Get-ChildItem $out -Filter *.f16 | % {"$($_.Name) $((Get-FileHash $_.FullName).Hash.Substring(0,8))"}

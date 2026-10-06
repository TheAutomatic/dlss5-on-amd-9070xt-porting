param([string]$Mods='',[string]$Srgb='1',[string]$Res='1920x1080',[string]$Skip='42,43,46',[int]$AE=0,[int]$Frames=1,[string]$Tag='a',[string]$Height='1080')
$ErrorActionPreference='Stop'
if(Get-Process -ErrorAction SilentlyContinue | ? {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark$|^Magpie'}){throw 'GPU busy'}
$w='D:\DLSSNR-Lab\fidelity-ngx-20260930'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD'
$out="$w\out-$Tag-$Res";New-Item -ItemType Directory -Force $out|Out-Null
$drop='^(DLSS5_PRE_UPSCALE|DLSS5_SHOW_FPS|DLSS5_NETWORK_HEIGHT|DLSS5_FRAME_STATS|DLSS5_VIT_ADAPTIVE|DLSS5_VIT_REUSE_HOTKEY|DLSS5_SKIP_BLOCKS|DLSS5_OUTPUT_SMOOTH|DLSS5_STRENGTH|DLSS5_CODEC_SRGB|DLSS5_DIRECT_IO|DLSS5_FIT_INPUT|DLSS5_FIT_LARGE|DLSS5_HOT_RELOAD)='
$flags=@(Get-Content "$g\native-game-flags.txt" | ? {$_ -notmatch $drop})+@('DLSS5_PRE_UPSCALE=0','DLSS5_SHOW_FPS=0',"DLSS5_NETWORK_HEIGHT=$Height","DLSS5_VIT_ADAPTIVE=$AE",'DLSS5_STRENGTH=1,1',"DLSS5_CODEC_SRGB=$Srgb",'DLSS5_FIT_INPUT=1','DLSS5_FIT_LARGE=1','DLSS5_HOT_RELOAD=0','DLSS5_RESIDUAL_RGB=0')
if($Skip -ne "none"){$flags+="DLSS5_SKIP_BLOCKS=$Skip"}
[IO.File]::WriteAllLines("$out\flags.txt",$flags)
$wh=$Res.Split('x');$env:BENCH_W=$wh[0];$env:BENCH_H=$wh[1]
& "$w\bench_ngx.exe" "$g\native-game-tiled-assets" "$out\flags.txt" "$w\in-$Res.f16" "$out\o" $Frames 0 $(if($Mods){"$w\$Mods"}else{"$g\native-game-tiled-assets\HIP\gfx1201"}) 0 0 0 0 > "$out\run.log" 2> "$out\stderr.log"
"exit=$LASTEXITCODE"; Get-Content "$out\run.log" | select -Last 3

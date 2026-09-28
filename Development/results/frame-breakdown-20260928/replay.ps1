# frame-breakdown: offline NativeGameFrame replay with current Stellar modules/flags, span probe on (HIP GPU span vs frame wall).
param([int]$Height=1080,[int]$Frames=600,[int]$Span=1)
$ErrorActionPreference='Stop'
if(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark$'}){throw 'GPU busy'}
$r='D:\DLSSNR-Lab\hip-backend';$root="$r\float-fma";$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD'
$out="D:\DLSSNR-Lab\frame-breakdown-20260928\span-$Height-$Span";New-Item -ItemType Directory -Force $out|Out-Null
$flags=@(Get-Content "$g\native-game-flags.txt" | Where-Object {$_ -notmatch '^(DLSS5_PRE_UPSCALE|DLSS5_SHOW_FPS|DLSS5_NETWORK_HEIGHT|DLSS5_FRAME_STATS|DLSS5_VIT_ADAPTIVE|DLSS5_VIT_REUSE_HOTKEY)='})+@('DLSS5_PRE_UPSCALE=0','DLSS5_SHOW_FPS=0',"DLSS5_NETWORK_HEIGHT=$Height",'DLSS5_VIT_ADAPTIVE=0','DLSS5_RESIDUAL_RGB=0')
[IO.File]::WriteAllLines("$out\flags.txt",$flags)
$env:DLSS5_HIP_SPAN_PROBE="$Span";if($Span -eq 2){$env:DLSS5_GAME_PROBE="1";$env:DLSS5_HIP_SPAN_PROBE="0"}
$mods="$g\native-game-tiled-assets\HIP\gfx1201";if(!(Test-Path $mods)){$mods="$root\flat-P"}
& "$root\benchmark.exe" "$a\native-game-tiled-assets" "$out\flags.txt" "$r\live-menu-before.f16" "$out\rgb" $Frames 0 $mods 0 1 0 0 > "$out\run.log" 2> "$out\stderr.log"
if($LASTEXITCODE){throw "Replay failed"}
$rows=@(Import-Csv "$out\rgb.csv");$w=($rows|Where-Object{[int]$_.frame -ge 200}|Measure-Object wall_ms -Average).Average
$sp=@(Select-String -Path "$out\stderr.log" -Pattern 'hip_span gpu_ms=([0-9.]+) cpu_enqueue_ms=([0-9.]+)' | ForEach-Object {[double]$_.Matches[0].Groups[1].Value});$sp=$sp[200..($sp.Count-1)]
"mods=$mods height=$Height frames=$Frames wall_ms_avg=$([math]::Round($w,3)) hip_span_avg=$([math]::Round(($sp|Measure-Object -Average).Average,3)) n_span=$($sp.Count)"

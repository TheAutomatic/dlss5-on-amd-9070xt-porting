# A/B/A/B of DLSS5_MAKE_RESIDENT_EVERY in offline NativeGameFrame replay (per-frame wall_ms from benchmark csv)
param([int]$Height=1080,[int]$Frames=1200)
$ErrorActionPreference='Stop'
if(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^Magpie'}){throw 'GPU busy'}
$r='D:\DLSSNR-Lab\hip-backend';$root="$r\float-fma";$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD'
$base='D:\DLSSNR-Lab\resident-spike-20260929';New-Item -ItemType Directory -Force $base|Out-Null
$mods="$g\native-game-tiled-assets\HIP\gfx1201";if(!(Test-Path $mods)){$mods="$root\flat-P"}
$env:DLSS5_BENCH_PLAIN='1'
foreach($cfg in @(@('A1',60),@('B1',0),@('A2',60),@('B2',0))){
 $name=$cfg[0];$val=$cfg[1];$out="$base\$name";New-Item -ItemType Directory -Force $out|Out-Null
 $flags=@(Get-Content "$g\native-game-flags.txt" | Where-Object {$_ -notmatch '^(DLSS5_PRE_UPSCALE|DLSS5_SHOW_FPS|DLSS5_NETWORK_HEIGHT|DLSS5_FRAME_STATS|DLSS5_VIT_ADAPTIVE|DLSS5_VIT_REUSE_HOTKEY|DLSS5_MAKE_RESIDENT_EVERY)='})+@('DLSS5_PRE_UPSCALE=0','DLSS5_SHOW_FPS=0',"DLSS5_NETWORK_HEIGHT=$Height",'DLSS5_VIT_ADAPTIVE=0','DLSS5_RESIDUAL_RGB=0',"DLSS5_MAKE_RESIDENT_EVERY=$val")
 [IO.File]::WriteAllLines("$out\flags.txt",$flags)
 $env:DLSS5_MAKE_RESIDENT_EVERY="$val"
 & "$root\benchmark.exe" "$a\native-game-tiled-assets" "$out\flags.txt" "$r\live-menu-before.f16" "$out\rgb" $Frames 0 $mods 0 1 0 0 > "$out\run.log" 2> "$out\stderr.log"
 if($LASTEXITCODE){throw "Replay $name failed"}
 Copy-Item "$out\rgb.csv" "$base\$name.csv" -Force
 "$name every=$val done"
}

# per-step GPU breakdown with the input-slim probe host (DLSS5_GAME_PROBE=1 in flags; flushes every frame, so wall is not comparable)
param([string]$Exe='benchmark-probe.exe',[string]$Assets='assets-base',[string]$Tag='probe',[int]$Frames=600)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\input-slim-20261001';$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
foreach($h in 900,1080){
 if(Get-Process -ErrorAction SilentlyContinue|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^Magpie'}){throw 'GPU busy'}
 $dir="$root\$Tag-$h";if(Test-Path $dir){Remove-Item $dir -Recurse -Force};New-Item -ItemType Directory -Force $dir|Out-Null
 $flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$h",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_GAME_PROBE=1')
 [IO.File]::WriteAllLines("$dir\flags.txt",$flags)
 $logs=Join-Path $root 'logs';if(Test-Path "$logs\native-game-probe.txt"){Remove-Item "$logs\native-game-probe.txt"}
 & "$root\$Exe" "$root\$Assets" "$dir\flags.txt" "$r\live-menu-before.f16" "$dir\rgb" $Frames 0 "$root\flat-A" 0 1 0 0 > "$dir\run.log" 2> "$dir\stderr.log"
 if($LASTEXITCODE){throw "Replay failed $h"}
 Get-ChildItem $root -Recurse -Filter 'native-game-probe.txt' | ForEach-Object { Copy-Item $_.FullName "$dir\probe.txt"; Remove-Item $_.FullName }
 "== $h";if(Test-Path "$dir\probe.txt"){Get-Content "$dir\probe.txt"|Select-Object -Skip 2}else{'NO PROBE LOG';Get-ChildItem $root -Recurse -Filter '*.txt'|Where-Object{$_.LastWriteTime -gt (Get-Date).AddMinutes(-3)}|ForEach-Object FullName}
}

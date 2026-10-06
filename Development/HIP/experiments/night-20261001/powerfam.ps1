# night-20261001 #2: per-family clock/power on the installed exact tier. Each case duplicates one kernel family xN (DLSS5_HIP_DUP_PREFIX/COUNT)
# so it dominates the frame; ADL telemetry (clock_observe_telemetry 200 ms) gives clock/power under that family. Host benchmark-S (rebuild-baseline,
# = installed add-on source), modules = Stellar installed gfx1201. span = SPAN_PROBE median. Takes gpu.lock (with refresh job).
param([int]$Rounds=2,[int]$Frames=400,[int]$Count=8,[string]$Heights='900,1080',[string]$Cases='base,c32_wave1_,c64_wave2_,c128_wave2_,c512_qkv_attention_compact,split_ffn_one,mh_attention_project_frag_c512,split_projection_frag,vit_stream_,vit_attention_fused,vit_expand,vit_pack_input',[string]$Mods='',[string]$Tag='p')
$ErrorActionPreference='Stop';$root="D:\DLSSNR-Lab\night-20261001\power-$Tag";$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$L='D:\DLSSNR-Lab\gpu.lock';$me="night-20261001 power $Tag"
$t0=Get-Date
while(Test-Path $L){ if(((Get-Date)-(Get-Item $L).LastWriteTime).TotalMinutes -gt 40){Remove-Item $L -Force;"stale lock removed";break}
 if(((Get-Date)-$t0).TotalMinutes -gt 30){"LOCK TIMEOUT: $(Get-Content $L)";exit 1}; Start-Sleep 60}
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie'}){"GAME RUNNING";exit 1}
"$me $(Get-Date -Format s)"|Out-File -Encoding ascii $L
$j=Start-Job -ScriptBlock {param($L,$me) while($true){Start-Sleep 300; if(Test-Path $L){"$me $(Get-Date -Format s) (refresh)"|Out-File -Encoding ascii $L}}} -ArgumentList $L,$me
try{
New-Item -ItemType Directory -Force "$root\flat"|Out-Null;Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\flat" -Force
Copy-Item "$r\rebuild-baseline-20261001\benchmark-S.exe" "$root\bench.exe" -Force
foreach($m in ($Mods -split ','|?{$_})){$mod,$src=$m -split '=';Copy-Item $src "$root\flat\$mod.hsaco" -Force;"mod $mod <- $src $((Get-FileHash "$root\flat\$mod.hsaco").Hash.Substring(0,8))"}
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash.Substring(0,8)) mhpw $((Get-FileHash "$root\flat\multihead-fast-padded-wave-packed.hsaco").Hash.Substring(0,8))"
$caseList=@($Cases -split ",")
foreach($round in 1..$Rounds){foreach($h in ($Heights -split ',')){$rows=1152;foreach($c in $caseList){
 if(Test-Path 'D:\DLSSNR-Lab\night-20261001\ABORT'){throw 'ABORT game'}
 $tag="r$round-h$h-$($c.TrimEnd('$').TrimEnd('_'))"
 $flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$h",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_HIP_SPAN_PROBE=1','DLSS5_VIT_ADAPTIVE_IDLE_MS=1000000000',"DLSS5_NETWORK_1080_ROWS=$rows")
 if($c -ne 'base'){$flags+="DLSS5_HIP_DUP_PREFIX=$c";$flags+="DLSS5_HIP_DUP_COUNT=$Count";$env:DLSS5_HIP_DUP_PREFIX=$c;$env:DLSS5_HIP_DUP_COUNT="$Count"}else{Remove-Item Env:DLSS5_HIP_DUP_PREFIX,Env:DLSS5_HIP_DUP_COUNT -EA 0}
 $env:DLSS5_HIP_SPAN_PROBE='1'
 $ft="$root\$tag-flags.txt";[IO.File]::WriteAllLines($ft,$flags)
 $p=Start-Process "$r\clock_observe_telemetry.exe" -ArgumentList '200' -PassThru -NoNewWindow -RedirectStandardOutput "$root\$tag.tel" -RedirectStandardError "$root\$tag.telerr"
 Start-Sleep -Milliseconds 600
 try{$ErrorActionPreference='Continue';& "$root\bench.exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' $ft "$r\live-menu-before.f16" "$root\$tag" $Frames 0 "$root\flat" 0 1 0 0 > "$root\$tag.log" 2> "$root\$tag.err";$ec=$LASTEXITCODE;$ErrorActionPreference='Stop'}
 finally{if(!$p.HasExited){Stop-Process -Id $p.Id -Force}}
 $s=@(Select-String -Path "$root\$tag.err" -Pattern 'hip_span gpu_ms=([0-9.]+)'|%{[double]$_.Matches[0].Groups[1].Value}|Select-Object -Skip 60|Sort-Object)
 "SPAN $tag exit=$ec n=$($s.Count) med=$($s[[int]($s.Count/2)])"
 Get-ChildItem $root -Filter *.f16|Remove-Item -Force;Get-ChildItem $root -Filter *.ppm|Remove-Item -Force
}}}
'POWER_DONE'
} finally { Remove-Item Env:DLSS5_HIP_DUP_PREFIX,Env:DLSS5_HIP_DUP_COUNT -EA 0; Stop-Job $j; Remove-Job $j -Force; if((Test-Path $L) -and ((Get-Content $L) -match 'night-20261001')){Remove-Item $L -Force}; "LOCK DROPPED" }

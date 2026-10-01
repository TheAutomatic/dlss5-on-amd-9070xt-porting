# gap-map-evening #2: in-chain marginal cost of the ViT kernels by DUP replay (no events), 900 and 1080x1088 rows. Host benchmark-E (HEAD),
# modules = Stellar installed now. (span_dup - span_base)/8 per instance. Rounds interleave base and cases. Takes gpu.lock.
param([int]$Rounds=3,[int]$Frames=300,[string]$Mods='',[string]$Cases='base,vit_stream_qkv_frag_hin_w5f8$,vit_attention_fused_,vit_stream_contract_frag_hout$,vit_stream_project_n64_bh$,vit_expand_blocked_fp8_frag_bytein$',[string]$Prefix='')
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\gap-map-evening-20261001\dup';$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$L='D:\DLSSNR-Lab\gpu.lock';$me='gap-map-evening dup'
$t0=Get-Date
while(Test-Path $L){ if(((Get-Date)-(Get-Item $L).LastWriteTime).TotalMinutes -gt 40){Remove-Item $L -Force;"stale lock removed";break}
 if(((Get-Date)-$t0).TotalMinutes -gt 30){"LOCK TIMEOUT: $(Get-Content $L)";exit 1}; Start-Sleep 60}
if(Get-Process|?{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall'}){throw 'game running'}
"$me $(Get-Date -Format s)"|Out-File -Encoding ascii $L
$j=Start-Job -ScriptBlock {param($L,$me) while($true){Start-Sleep 300; if(Test-Path $L){"$me $(Get-Date -Format s) (refresh)"|Out-File -Encoding ascii $L}}} -ArgumentList $L,$me
try{
New-Item -ItemType Directory -Force "$root\flat"|Out-Null;Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\flat" -Force
Copy-Item "$r\gap-map-evening-20261001\benchmark-E.exe" "$root\bench.exe" -Force
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash.Substring(0,8)) vit $((Get-FileHash "$root\flat\vit-stream.hsaco").Hash.Substring(0,8))"
foreach($m in ($Mods -split ','|?{$_})){$mod,$b=$m -split '=';Copy-Item "D:\DLSSNR-Lab\hip-backend\gap-map-evening-20261001\build-$b\gfx1201\$mod.hsaco" "$root\flat" -Force;"mod $mod <- $b $((Get-FileHash "$root\flat\$mod.hsaco").Hash.Substring(0,8))"}
$caseList=@($Cases -split ",")
foreach($round in 1..$Rounds){foreach($h in 900,1080){$rows=if($h -eq 900){1152}else{1088};foreach($c in $caseList){
 $tag="${Prefix}r$round-h$h-$($c.TrimEnd('$').TrimEnd('_'))"
 $flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$h",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_HIP_SPAN_PROBE=1','DLSS5_VIT_ADAPTIVE_IDLE_MS=1000000000',"DLSS5_NETWORK_1080_ROWS=$rows")
 if($c -ne 'base'){$flags+="DLSS5_HIP_DUP_PREFIX=$c";$flags+='DLSS5_HIP_DUP_COUNT=2';$env:DLSS5_HIP_DUP_PREFIX=$c;$env:DLSS5_HIP_DUP_COUNT='2'}else{Remove-Item Env:DLSS5_HIP_DUP_PREFIX,Env:DLSS5_HIP_DUP_COUNT -EA 0}
 $env:DLSS5_HIP_SPAN_PROBE='1'
 $ft="$root\$tag-flags.txt";[IO.File]::WriteAllLines($ft,$flags)
 $ErrorActionPreference='Continue';& "$root\bench.exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' $ft "$r\live-menu-before.f16" "$root\$tag" $Frames 0 "$root\flat" 0 1 0 0 > "$root\$tag.log" 2> "$root\$tag.err";$ec=$LASTEXITCODE;$ErrorActionPreference='Stop'
 $s=@(Select-String -Path "$root\$tag.err" -Pattern 'hip_span gpu_ms=([0-9.]+)'|%{[double]$_.Matches[0].Groups[1].Value}|Select-Object -Skip 60|Sort-Object)
 "SPAN $tag exit=$ec n=$($s.Count) med=$($s[[int]($s.Count/2)])"
}}}
Get-ChildItem $root -Recurse -Include *.f16,*.ppm|Remove-Item -Force
'DUP_DONE'
} finally { Remove-Item Env:DLSS5_HIP_DUP_PREFIX,Env:DLSS5_HIP_DUP_COUNT -EA 0; Stop-Job $j; Remove-Job $j -Force; if((Test-Path $L) -and ((Get-Content $L) -match 'gap-map-evening')){Remove-Item $L -Force}; "LOCK DROPPED" }

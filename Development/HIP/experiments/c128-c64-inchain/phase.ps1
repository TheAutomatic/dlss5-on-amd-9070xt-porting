# phase probe (c128-phase): flat-ph<b> = installed + c64-wave2 built with W2_PHASE_REP <b> (one phase of c128_wave2_bi_bo runs twice);
# (span_ph - span_base)/9 = in-chain cost of that phase. Original item-1 header:
# item 1: true in-chain marginal cost per kernel, no events. DLSS5_HIP_DUP_PREFIX=<kernel>$ + DUP_COUNT=2 relaunches every instance of that
# (pure, idempotent) kernel right after itself; (span_dup - span_base)/instances = cost of one more instance inside the production chain.
param([int]$Rounds=3)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\c128-c64-inchain-20261001';$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall'}){throw 'game running'}
New-Item -ItemType Directory -Force "$root\flat-dup"|Out-Null;Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\flat-dup" -Force
"c64-wave2 $((Get-FileHash "$root\flat-dup\c64-wave2.hsaco").Hash) addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash)"
Copy-Item "$r\kernel-map-inchain-20261001\evprof.exe" "$root\evprof.exe" -Force
$cases=@('base','ph1','ph2','ph4','ph8','ph16','ph32','dup')
foreach($c in $cases){if($c -like 'ph*'){New-Item -ItemType Directory -Force "$root\flat-$c"|Out-Null;Copy-Item "$root\flat-dup\*.hsaco" "$root\flat-$c" -Force;Copy-Item "$root\build-$c\gfx1201\c64-wave2.hsaco" "$root\flat-$c" -Force}}
foreach($round in 1..$Rounds){foreach($h in 900,1080){foreach($c in $cases){
 $tag="ph-r$round-h$h-$c";$fl=if($c -like 'ph*'){"$root\flat-$c"}else{"$root\flat-dup"}
 $flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$h",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_HIP_SPAN_PROBE=1')
 if($c -eq 'dup'){$flags+='DLSS5_HIP_DUP_PREFIX=c128_wave2_bi_bo$';$flags+='DLSS5_HIP_DUP_COUNT=2'}
 $env:DLSS5_HIP_SPAN_PROBE='1';Remove-Item Env:DLSS5_MAP_PROFILE -EA 0
 $ft="$root\$tag-flags.txt";[IO.File]::WriteAllLines($ft,$flags)
 $ErrorActionPreference='Continue';& "$root\evprof.exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' $ft "$r\live-menu-before.f16" "$root\$tag" 300 0 $fl 0 1 0 0 > "$root\$tag.log" 2> "$root\$tag.err";$ErrorActionPreference='Stop'
 $s=@(Select-String -Path "$root\$tag.err" -Pattern 'hip_span gpu_ms=([0-9.]+)'|ForEach-Object{[double]$_.Matches[0].Groups[1].Value}|Select-Object -Skip 60|Sort-Object)
 "SPAN $tag exit=$LASTEXITCODE n=$($s.Count) med=$($s[[int]($s.Count/2)])"
}}}
Get-ChildItem $root -Recurse -Include *.f16,*.ppm|Where-Object{$_.FullName -match 'ph-r'}|Remove-Item -Force
'PH_DONE'

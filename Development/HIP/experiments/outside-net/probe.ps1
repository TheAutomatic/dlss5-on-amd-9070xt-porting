# probe.ps1 (outside-net): timeline outside the network, both paths.
# add-on (bench host, Magpie flags as wall.ps1/next-candidate, DIRECT_IO=3): per host and tier
#   W = plain run 1000 frames -> CPU wall per frame (csv wall_ms, frames >= 200)
#   P = DLSS5_GAME_PROBE=1 + DLSS5_HIP_SPAN_PROBE=1, 600 frames -> D3D passes encode|input|network(gap incl. handoff)|neural|decode|copy,
#       cpu_frame (probe flushes each frame), hip span and cpu_enqueue_ms from the bridge
# runtime (rt_outside, ABI host): runtime-<side> x {serial, pipe} x {timing on, off}, 1600x900 and 1920x1080 (auto tier), 400 frames
param([string[]]$Hosts=@('base','Q'),[string[]]$Sides=@('base','D','DQ'),[switch]$SkipAddon,[switch]$SkipRt,[string]$Tag='p1')
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\outside-net-20261002';$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
function Med($v){if(!$v.Count){return 'na'};$s=@($v|Sort-Object);$s[[int]($s.Count/2)]}
function Busy{if(Get-Process -EA 0|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){throw 'GAME RUNNING'}}
function Flags($h,$x){@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$h",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_VIT_ADAPTIVE_IDLE_MS=1000000000','DLSS5_NETWORK_1080_ROWS=1152')+$x}
$out="$root\probe-$Tag";New-Item -ItemType Directory -Force $out|Out-Null
if(!$SkipAddon){foreach($pass in 1,2){foreach($hst in $Hosts){foreach($h in 900,1080){Busy
 $n="$hst-$h-$pass";$ft="$out\$n-W-flags.txt";[IO.File]::WriteAllLines($ft,(Flags $h @()))
 $ErrorActionPreference='Continue';& "$root\benchmark-$hst.exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' $ft "$r\live-menu-before.f16" "$out\$n-W" 1000 0 "$root\flat-A" 0 1 0 0 > "$out\$n-W.log" 2> "$out\$n-W.err";$ec=$LASTEXITCODE;$ErrorActionPreference='Stop'
 $w=@(Import-Csv "$out\$n-W.csv"|?{[int]$_.frame -ge 200}|%{[double]$_.wall_ms})
 "ADDON $n W exit=$ec wall_mean=$(($w|Measure-Object -Average).Average) wall_med=$(Med $w)"
 $ft="$out\$n-P-flags.txt";[IO.File]::WriteAllLines($ft,(Flags $h @('DLSS5_GAME_PROBE=1','DLSS5_HIP_SPAN_PROBE=1')))
 Get-ChildItem $root -Recurse -Filter 'native-game-probe.txt'|Remove-Item -Force
 $ErrorActionPreference='Continue';& "$root\benchmark-$hst.exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' $ft "$r\live-menu-before.f16" "$out\$n-P" 600 0 "$root\flat-A" 0 1 0 0 > "$out\$n-P.log" 2> "$out\$n-P.err";$ec=$LASTEXITCODE;$ErrorActionPreference='Stop'
 $pl=@(Get-ChildItem $root -Recurse -Filter 'native-game-probe.txt'|%{Get-Content $_.FullName});$pl|Set-Content "$out\$n-P-probe.txt";Get-ChildItem $root -Recurse -Filter 'native-game-probe.txt'|Remove-Item -Force
 $sp=@(Select-String -Path "$out\$n-P.err" -Pattern 'hip_span gpu_ms=([0-9.]+) cpu_enqueue_ms=([0-9.]+)'|%{,@([double]$_.Matches[0].Groups[1].Value,[double]$_.Matches[0].Groups[2].Value)});if($sp.Count -gt 150){$sp=$sp[150..($sp.Count-1)]}
 $w=@(Import-Csv "$out\$n-P.csv"|?{[int]$_.frame -ge 150}|%{[double]$_.wall_ms})
 "ADDON $n P exit=$ec wall_med=$(Med $w) span_med=$(Med @($sp|%{$_[0]})) cpu_enqueue_med=$(Med @($sp|%{$_[1]})) | $(($pl|Select-Object -Skip 1) -join ' || ')"
 Get-ChildItem $out -Include *.f16,*.ppm -Recurse|Remove-Item -Force}}}}
if(!$SkipRt){
 $env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1';Remove-Item Env:DLSS5_NETWORK_HEIGHT -EA 0
 foreach($pass in 1,2){foreach($mode in @(@('serial','0','1'),@('serial','0','0'),@('pipe','1','1'),@('pipe','1','0'))){foreach($side in $Sides){Busy
  $d="$root\rt\runtime-$side";$env:LMXXF_SHADER_DIR="$d\shaders";$env:OUT_PIPE=$mode[1];$env:OUT_TIMING=$mode[2]
  $n="rt-$side-$($mode[0])-t$($mode[2])-$pass";& "$root\rt_outside.exe" "$d\LmxxfNrRuntime.dll" "$d\modules" '1600x900,1920x1080' 400 1 *> "$out\$n.log";$ec=$LASTEXITCODE
  "RT $n exit=$ec"; Select-String -Path "$out\$n.log" -Pattern '^outside size|^round=' | %{ '  '+$_.Line.Substring(0,[Math]::Min(200,$_.Line.Length)) }}}}
 Remove-Item Env:OUT_PIPE,Env:OUT_TIMING -EA 0}
'PROBE_DONE'

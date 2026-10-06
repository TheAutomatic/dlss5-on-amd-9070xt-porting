# gap-map-evening-20261001: installed Stellar modules (exact tier) + HEAD hosts. (1) whole-net wall/span 900, 1080x1152, 1080x1088, two passes; (2) in-chain per-dispatch map (evprof-E = HEAD + event-profile-v4 + step/SP split) at 900/1152/1088, profiled and plain.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\gap-map-evening-20261001';$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall'}){throw 'game running'}
Remove-Item -Recurse -Force "$root\flat" -EA 0;New-Item -ItemType Directory -Force "$root\flat"|Out-Null;Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\flat" -Force
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash)"|Set-Content "$root\installed.txt"
Get-ChildItem "$root\flat"|ForEach-Object{"$($_.Name) $((Get-FileHash $_.FullName).Hash)"}|Add-Content "$root\installed.txt"
"benchmark-E $((Get-FileHash "$root\benchmark-E.exe").Hash) evprof-E $((Get-FileHash "$root\evprof-E.exe").Hash)"|Add-Content "$root\installed.txt"
& "$root\lock.ps1" take gap-map-evening;if($LASTEXITCODE){exit 1}
function Med($v){if(!$v.Count){return 'na'};$s=$v|Sort-Object;$s[[int]($s.Count/2)]}
function Flags($h,$rows,$extra){@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$h",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_HIP_SPAN_PROBE=1','DLSS5_VIT_ADAPTIVE_IDLE_MS=1000000000',"DLSS5_NETWORK_1080_ROWS=$rows")+$extra}
$env:DLSS5_HIP_SPAN_PROBE='1'
try{
 if(-not $env:GM_SKIP_WALL){
 foreach($pass in 1,2){foreach($c in @(@(900,1152),@(1080,1152),@(1080,1088))){
  $n="wall-$($c[0])-$($c[1])-$pass";$ft="$root\$n-flags.txt";[IO.File]::WriteAllLines($ft,(Flags $c[0] $c[1] @()))
  $ErrorActionPreference='Continue';& "$root\benchmark-E.exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' $ft "$r\live-menu-before.f16" "$root\$n" 1000 0 "$root\flat" 0 1 0 0 > "$root\$n.log" 2> "$root\$n.err";$ec=$LASTEXITCODE;$ErrorActionPreference='Stop'
  $w=@(Import-Csv "$root\$n.csv"|?{[int]$_.frame -ge 200}|%{[double]$_.wall_ms})
  $sp=@(Select-String -Path "$root\$n.err" -Pattern 'hip_span gpu_ms=([0-9.]+)'|%{[double]$_.Matches[0].Groups[1].Value});if($sp.Count -gt 200){$sp=$sp[200..($sp.Count-1)]}
  "$n exit=$ec wall_mean=$(($w|Measure-Object -Average).Average) wall_med=$(Med $w) span_med=$(Med $sp)"|Tee-Object -Append "$root\wall.txt"
 }}}
 foreach($c in @(@(900,1152),@(1080,1152),@(1080,1088))){foreach($prof in 1,0){
  $tag="h$($c[0])-r$($c[1])-p$prof";$ex=@();if($prof){$ex+='DLSS5_MAP_PROFILE=1';$env:DLSS5_MAP_PROFILE='1'}else{Remove-Item Env:DLSS5_MAP_PROFILE -EA 0}
  $ft="$root\$tag-flags.txt";[IO.File]::WriteAllLines($ft,(Flags $c[0] $c[1] $ex))
  $ErrorActionPreference='Continue';& "$root\evprof-E.exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' $ft "$r\live-menu-before.f16" "$root\$tag" 300 0 "$root\flat" 0 1 0 0 > "$root\$tag.log" 2> "$root\$tag.err";$ErrorActionPreference='Stop'
  "$tag exit=$LASTEXITCODE kev=$(@(Select-String -Path "$root\$tag.log" -Pattern '^KEV,').Count)"|Tee-Object -Append "$root\map.txt"
 }}
}finally{Remove-Item Env:DLSS5_MAP_PROFILE -EA 0;& "$root\lock.ps1" drop gap-map-evening}
Get-ChildItem $root -Recurse -Include *.f16,*.ppm|Where-Object{$_.DirectoryName -ne "$root\flat"}|Remove-Item -Force
'RUN_DONE'

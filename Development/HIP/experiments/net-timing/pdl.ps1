# pdl.ps1 (net-timing #2, PDL bug): the three shipped templates (scripts\hip-*-flags.txt, PDL=1 SWIN_RUN=1 ...), 1000 frames,
# DLSS5_NET_TIMING_FENCE 0 (first version) vs 1 (fix), with DLSS5_HIP_SPAN_PROBE=1 as the reference.
# runtime: rt_timing + template as <dll>\DLSS5-AMD\native-game-flags.txt; add-on: bench host T2 + template (+ bench overrides), DLSS5_NET_TIMING=2.
param([string]$Dll='bin\v2\LmxxfNrRuntime.dll',[string]$Bench='bin\v2\benchmark-T2.exe',[int]$Frames=1000,[string[]]$Fences=@('0','1'),[int[]]$Heights=@(900,1080),[string]$Tag='pdl',[string[]]$Templates=@('hip-game-flags','hip-magpie-flags','hip-re9-flags'),[string]$Span='1',[string]$Pipe='0',[switch]$SkipAddon,[switch]$SkipRt,[string]$ExtraLine='')
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\net-timing-20261002';$out="$root\$Tag";$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$r='D:\DLSSNR-Lab\hip-backend'
New-Item -ItemType Directory -Force $out|Out-Null
function Med($v){if(!$v.Count){return 0};$s=@($v|Sort-Object);$s[[int]($s.Count/2)]}
function Stat($name,$t,$s){$m=Med $t;"$name n=$($t.Count) med=$($m.ToString('F3')) min=$((($t|Measure-Object -Minimum).Minimum).ToString('F3')) lt1ms=$(@($t|?{$_ -lt 1}).Count) lt70pct=$(@($t|?{$_ -lt 0.7*$m}).Count) lows=$((@($t|?{$_ -lt 0.7*$m})|Select-Object -First 8|%{$_.ToString('F3')}) -join ',') | span n=$($s.Count) med=$((Med $s).ToString('F3')) lt70pct=$(@($s|?{$_ -lt 0.7*(Med $s)}).Count)"}
$base=@{LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';LMXXF_SHADER_DIR='D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders';DLSS5_HIP_SPAN_PROBE=$Span;RT_PIPE=$Pipe}
foreach($tpl in $Templates){foreach($fence in $Fences){foreach($h in $Heights){
 foreach($k in $base.Keys){Set-Item "Env:$k" $base[$k]};$env:DLSS5_NET_TIMING_FENCE=$fence;$env:DLSS5_NETWORK_HEIGHT="$h";Remove-Item Env:DLSS5_NET_TIMING -EA 0
 # runtime
 if(!$SkipRt){
 $d="$out\rt-$tpl";if(!(Test-Path "$d\modules\gfx1201")){New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\DLSS5-AMD","$d\shaders"|Out-Null;Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders";foreach($a in 'gfx1200','gfx1201'){Copy-Item "$oni\DLSS5-AMD\native-game-tiled-assets\HIP\$a\*.hsaco" "$d\modules\$a"}
  $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring(("$d\modules\").Length).Replace('\','/'))"});[IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)
  Copy-Item "$root\templates\$tpl.txt" "$d\DLSS5-AMD\native-game-flags.txt"}
 Copy-Item "$root\$Dll" "$d\LmxxfNrRuntime.dll" -Force
 $env:LMXXF_SHADER_DIR="$d\shaders";$log="$out\rt-$tpl-f$fence-$h.log";$ErrorActionPreference='Continue';& "$root\bin\rt_timing.exe" "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' $Frames 1 *> $log;$ec=$LASTEXITCODE;$ErrorActionPreference='Stop'
 $t=@(Select-String -Path $log -Pattern '^timing frame=(\d+) valid=1 ms=([0-9.]+)'|?{[int]$_.Matches[0].Groups[1].Value -ge 10}|%{[double]$_.Matches[0].Groups[2].Value})
 $s=@(Select-String -Path $log -Pattern 'hip_span gpu_ms=([0-9.-]+)'|Select-Object -Skip 10|%{[double]$_.Matches[0].Groups[1].Value})
 Stat "RT $tpl dll=$Dll pipe=$Pipe fence=$fence $h exit=$ec $((Select-String -Path $log -Pattern tiny_reads=\d+).Matches.Value) pdl=$([regex]::Match((Get-Content $log -Raw),'pdl=[0-9/]+').Value)" $t $s
 }
 # add-on bench
 if(!$SkipAddon){
 $f="$out\bench-$tpl-$h.txt";[IO.File]::WriteAllLines($f,@(Get-Content "$root\templates\$tpl.txt")+@('DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0','DLSS5_PRE_UPSCALE_ASYNC=0',"DLSS5_NETWORK_HEIGHT=$h",'DLSS5_VIT_ADAPTIVE_IDLE_MS=1000000000','DLSS5_NET_TIMING=2',"DLSS5_NET_TIMING_FENCE=$fence","DLSS5_HIP_SPAN_PROBE=$Span")+@($ExtraLine|?{$_}))
 $bo="$out\bench-$tpl-f$fence-$h";$ErrorActionPreference='Continue';& "$root\$Bench" "$root\assets-base" $f "$r\live-menu-before.f16" $bo $Frames 0 "$root\flat-A" 0 1 0 0 > "$bo.log" 2> "$bo.err";$ec=$LASTEXITCODE;$ErrorActionPreference='Stop'
 $t=@(Select-String -Path "$bo.err" -Pattern '^net_timing tag=\d+ ms=([0-9.]+)'|Select-Object -Skip 10|%{[double]$_.Matches[0].Groups[1].Value})
 $s=@(Select-String -Path "$bo.err" -Pattern 'hip_span gpu_ms=([0-9.-]+)'|Select-Object -Skip 10|%{[double]$_.Matches[0].Groups[1].Value})
 Stat "ADDON $tpl extra=$ExtraLine fence=$fence $h exit=$ec" $t $s}
 Get-ChildItem $out -Include *.f16,*.ppm -Recurse|Remove-Item -Force}}}
'PDL_DONE'

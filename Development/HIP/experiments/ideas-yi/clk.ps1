# clk.ps1 (ideas-yi): clock/power under one host+env config, ADL 200 ms telemetry (clock_observe_telemetry), base and candidate
# alternated (B C C B), 900 and 1080, 1000 frames each. Output: CLK lines with median sensor1 (MHz) / sensor73 (W) for GFX activity >= 90%.
# Called from inside a lock holder (go-skew -Clk) or standalone after taking the lock itself.
param([string]$Host2='K',[string]$Env='',[string]$Mods='flat-A',[string]$Tag='c')
$root='D:\DLSSNR-Lab\hip-backend\ideas-yi-20261002';$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
function Med($v){if(!$v.Count){return 'na'};$s=@($v|Sort-Object);$s[[int]($s.Count/2)]}
foreach($h in 900,1080){foreach($slot in 0..3){$cand=$slot -in 1,2;$n="clk-$Tag-$h-$slot"
 $flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$h",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_VIT_ADAPTIVE_IDLE_MS=1000000000')
 $ft="$root\$n-flags.txt";[IO.File]::WriteAllLines($ft,$flags)
 foreach($kv in ($Env -split ';'|?{$_})){$k,$v=$kv -split '=';if($cand){Set-Item "Env:$k" $v}else{Remove-Item "Env:$k" -EA 0}}
 $exe=if($cand){"$root\benchmark-$Host2.exe"}else{"$root\benchmark-base.exe"};$mods=if($cand){"$root\$Mods"}else{"$root\flat-A"}
 $p=Start-Process "$r\clock_observe_telemetry.exe" -ArgumentList '200' -PassThru -NoNewWindow -RedirectStandardOutput "$root\$n.tel" -RedirectStandardError "$root\$n.telerr"
 Start-Sleep -Milliseconds 600
 try{$ErrorActionPreference='Continue';& $exe "$root\assets-base" $ft "$r\live-menu-before.f16" "$root\$n" 1000 0 $mods 0 1 0 0 > "$root\$n.log" 2> "$root\$n.err";$ErrorActionPreference='Stop'}finally{if(!$p.HasExited){Stop-Process -Id $p.Id -Force}}
 $L=@(Get-Content "$root\$n.tel"|?{$_ -match 'adapter=0 ' -and $_ -match 'status=0' -and $_ -match 'sensor19=(\d+)' -and [int]$Matches[1] -ge 90});$L=$L[[int]($L.Count/4)..($L.Count-1)]
 $clk=@($L|%{if($_ -match 'sensor1=(\d+)'){[int]$Matches[1]}});$pw=@($L|%{if($_ -match 'sensor73=(\d+)'){[int]$Matches[1]}})
 $w=@(Import-Csv "$root\$n.csv"|?{[int]$_.frame -ge 200}|%{[double]$_.wall_ms})
 "CLK $Tag h=$h slot=$slot cand=$cand n=$($L.Count) clk_med=$(Med $clk) pw_med=$(Med $pw) wall_avg=$(($w|Measure-Object -Average).Average)"
 Get-ChildItem $root -Filter "$n*" -Include *.f16,*.ppm -EA 0|Remove-Item -Force -EA 0}}
foreach($kv in ($Env -split ';'|?{$_})){$k,$v=$kv -split '=';Remove-Item "Env:$k" -EA 0}
Get-ChildItem $root -Filter *.f16 -EA 0|Remove-Item -Force -EA 0

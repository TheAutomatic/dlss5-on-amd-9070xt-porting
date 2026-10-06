param([switch]$SkipQuality,[switch]$SkipTiming,[int]$Rounds=2)
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend';$root='D:\DLSSNR-Lab\geom1088-20260930';$d="$root\geom";$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD';$assets='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
function Idle { if(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile|^microbench|^runtime-smoke|^jobbench|^Magpie'}){throw 'Game running'} }
function One($tag,$height,$seq,$frames,$temporal=0,$extra=@()){
 Idle;$dir="$d\$tag";New-Item -ItemType Directory -Force $dir|Out-Null
 $flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$height",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=',"DLSS5_RESIDUAL_SEQUENCE=$seq","DLSS5_RESIDUAL_RGB=$(if($frames -eq 12){1}else{0})",'DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60')
 $keys=$extra|%{($_ -split '=')[0]};$flags=@($flags|?{($_ -split '=')[0] -notin $keys})+$extra
 [IO.File]::WriteAllLines("$dir\flags.txt",$flags)
 & "$root\benchmark-P.exe" $assets "$dir\flags.txt" "$r\live-menu-before.f16" "$dir\rgb" $frames $temporal "$root\flat-A" 0 $(if($frames -eq 12){0}else{1}) 0 0 > "$dir\run.log"
 if($LASTEXITCODE){throw "Replay failed $tag"};Idle
 $rows=@(Import-Csv "$dir\rgb.csv");if($rows.Count -ne $frames -or @($rows|Where-Object{$_.checked -eq '1' -and [int]$_.invalid -ne 0}).Count){throw 'Invalid frames'}
 $mean=($rows|Where-Object{[int]$_.frame -ge $(if($frames -eq 12){1}elseif($frames -ge 1000){200}else{32})}|Measure-Object wall_ms -Average).Average
 [pscustomobject]@{tag=$tag;mean_ms=$mean}|ConvertTo-Json -Compress
}
function Same($b,$t){$files=@(Get-ChildItem "$d\$b" -Filter '*frame-*.f16');$different=0;foreach($f in $files){if((Get-FileHash $f.FullName).Hash -ne (Get-FileHash "$d\$t\$($f.Name)").Hash){$different++}};"$(if($different){'DIFF'}else{'SAME'}) $b $t ($different/$($files.Count))"}
if(!$SkipQuality){
 foreach($case in @(@{n='static';s=0;t=0},@{n='motion';s=1;t=0},@{n='history';s=5;t=1})){
  One "$($case.n)-1152" 1080 $case.s 12 $case.t
  One "$($case.n)-1088" 1088 $case.s 12 $case.t
  One "$($case.n)-1088rows" 1080 $case.s 12 $case.t @('DLSS5_NETWORK_1080_ROWS=1088')
  Same "$($case.n)-1088" "$($case.n)-1088rows"
  One "$($case.n)-1088plain" 1088 $case.s 12 $case.t @('DLSS5_HIP_SWIN_RUN=0','DLSS5_HIP_WAVE_OWNED=0')
  Same "$($case.n)-1088" "$($case.n)-1088plain"
  One "$($case.n)-1152plain" 1080 $case.s 12 $case.t @('DLSS5_HIP_SWIN_RUN=0','DLSS5_HIP_WAVE_OWNED=0')
  Same "$($case.n)-1152" "$($case.n)-1152plain"
 }
}
if(!$SkipTiming){foreach($round in 1..$Rounds){foreach($slot in 0..3){$h=if($slot -in 1,2){1088}else{1080};One "time$round-$slot-$h" $h 0 1000}}}
'GEOM_DONE'

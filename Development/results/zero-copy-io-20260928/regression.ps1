# zero-copy-io: DLSS5_BENCH_PLAIN=1 = non-temporal session like in-game Stellar (direct input only engages there). Same benchmark exe and modules (current Stellar production), DLSS5_DIRECT_IO=0 (previous path) vs 1 (direct input).
# 7 cases x 12 frames: per-frame RGB hashes must match. Timing ABBA 1000 frames per slot (slots 0/3 = A, 1/2 = B), two batches, 900/1080.
param([string]$Batch='b1',[switch]$CorrectnessOnly,[switch]$TimingOnly,[int]$TimingFrames=1000,[int[]]$Heights=@(900,1080),[string]$CandidateIo='1')
$ErrorActionPreference='Stop'
$lab='D:\DLSSNR-Lab\zero-copy-io-20260928';$r='D:\DLSSNR-Lab\hip-backend'
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD'
$assets="$lab\assets";$mods="$g\native-game-tiled-assets\HIP\gfx1201";$exe="$lab\benchmark-zc.exe";$d="$lab\run-$Batch"
function Idle { if(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark'}){throw 'GPU busy'} }
Idle
$base=@(Get-Content "$g\native-game-flags.txt" | Where-Object {$_ -notmatch '^(DLSS5_PRE_UPSCALE|DLSS5_SHOW_FPS|DLSS5_NETWORK_HEIGHT|DLSS5_FRAME_STATS|DLSS5_VIT_ADAPTIVE|DLSS5_VIT_ADAPTIVE_LOG|DLSS5_VIT_REUSE_HOTKEY|DLSS5_RESIDUAL_SEQUENCE|DLSS5_RESIDUAL_RGB|DLSS5_DIRECT_IO)='})
function One($tag,$height,$seq,$io,$frames,$temporal=0,$adaptive=0,$plain='1'){
 Idle;$dir="$d\$tag";New-Item -ItemType Directory -Force $dir|Out-Null
 $adaptiveLog=if($frames -eq 12){"$dir\adaptive.csv"}else{''}
 $flags=$base+@('DLSS5_PRE_UPSCALE=0','DLSS5_SHOW_FPS=0',"DLSS5_NETWORK_HEIGHT=$height","DLSS5_VIT_ADAPTIVE=$adaptive","DLSS5_VIT_ADAPTIVE_LOG=$adaptiveLog","DLSS5_RESIDUAL_SEQUENCE=$seq","DLSS5_RESIDUAL_RGB=$(if($frames -eq 12){1}else{0})","DLSS5_DIRECT_IO=$io","DLSS5_BENCH_PLAIN=$plain")
 [IO.File]::WriteAllLines("$dir\flags.txt",$flags)
 & $exe $assets "$dir\flags.txt" "$r\live-menu-before.f16" "$dir\rgb" $frames $temporal $mods 0 $(if($frames -eq 12){0}else{1}) 0 0 > "$dir\run.log" 2> "$dir\stderr.log"
 if($LASTEXITCODE){throw "Replay failed $tag"};Idle
 $rows=@(Import-Csv "$dir\rgb.csv");if($rows.Count -ne $frames -or @($rows|Where-Object{$_.checked -eq '1' -and [int]$_.invalid -ne 0}).Count){throw "Invalid frames $tag"}
 $mean=($rows|Where-Object{[int]$_.frame -ge $(if($frames -eq 12){1}else{200})}|Measure-Object wall_ms -Average).Average
 [pscustomobject]@{tag=$tag;io=$io;mean_ms=[math]::Round($mean,4)}|ConvertTo-Json -Compress
}
function Same($b,$t){$files=@(Get-ChildItem "$d\$b" -Filter '*frame-*.f16');if($files.Count -ne 12){throw "Missing RGB frames $b"};foreach($f in $files){if((Get-FileHash $f.FullName).Hash -ne (Get-FileHash "$d\$t\$($f.Name)").Hash){throw "Output changed $t $($f.Name)"}};"SAME $b $t ($($files.Count) frames)"}
if(!$TimingOnly){
 foreach($case in @(@{n='900-static';h=900;s=0;t=0;a=0},@{n='900-motion';h=900;s=1;t=0;a=0},@{n='1080-static';h=1080;s=0;t=0;a=0},@{n='1080-motion';h=1080;s=1;t=0;a=0},@{n='720-motion';h=720;s=1;t=0;a=0},@{n='900-history';h=900;s=5;t=1;a=0},@{n='1080-history';h=1080;s=5;t=1;a=0},@{n='900-ae';h=900;s=1;t=0;a=1},@{n='1080-ae';h=1080;s=1;t=0;a=1})){
  foreach($io in '0',$CandidateIo){One "$($case.n)-io$io" $case.h $case.s $io 12 $case.t $case.a}
  Same "$($case.n)-io0" "$($case.n)-io$CandidateIo"
  # plain (non-temporal) session vs the host's usual temporal-capable session, old path: must also match
  if(!$case.t){One "$($case.n)-tc" $case.h $case.s '0' 12 $case.t $case.a '0';Same "$($case.n)-tc" "$($case.n)-io0"}
  if($case.a){$x=Get-FileHash "$d\$($case.n)-io0\adaptive.csv";$y=Get-FileHash "$d\$($case.n)-io$CandidateIo\adaptive.csv";if($x.Hash -ne $y.Hash){throw "AE decisions differ $($case.n)"};"AE-SAME $($case.n)"}
 }
}
if(!$CorrectnessOnly){foreach($h in $Heights){foreach($slot in 0..3){One "time-$h-$slot" $h 0 $(if($slot -in 1,2){$CandidateIo}else{'0'}) $TimingFrames}}}

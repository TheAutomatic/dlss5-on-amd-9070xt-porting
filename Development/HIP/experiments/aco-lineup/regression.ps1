# pack8 regression (template: c64-block-fused): same production host and flags, baseline module set modules-A (defaults),
# candidate modules-<Set>. 12-frame RGB per-frame hashes must match; timing ABBA 1000 frames (slots 0/3 A, 1/2 candidate).
param([string]$Set='B',[int]$Adaptive=0,[string]$BenchName='benchmark.exe',[string]$Batch='correct',[string]$Base='A',[string]$Arch='gfx1201',[string[]]$Only=@(),[switch]$SameSet,[switch]$CorrectnessOnly,[switch]$TimingOnly,[int]$TimingSequence=0,[int]$TimingFrames=1000,[int[]]$Heights=@(900,1080))
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend';$root=Split-Path -Parent $MyInvocation.MyCommand.Path;$d="$root\runtime-regression-$Set-$Batch";$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
$p=$root
function Idle { if(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall'}){throw 'Game running'} }
Idle
function One($tag,$height,$seq,$candidate,$frames,$temporal=0){
 Idle;$dir="$d\$tag";New-Item -ItemType Directory -Force $dir|Out-Null
 $adaptiveLog=if($frames -eq 12){"$dir\adaptive.csv"}else{''}
 $flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$height","DLSS5_VIT_ADAPTIVE=$Adaptive","DLSS5_VIT_ADAPTIVE_LOG=$adaptiveLog","DLSS5_RESIDUAL_SEQUENCE=$seq","DLSS5_RESIDUAL_RGB=$(if($frames -eq 12){1}else{0})",'DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1')
 [IO.File]::WriteAllLines("$dir\flags.txt",$flags)
 $runner="$p\$BenchName"
 $sub=if(Test-Path "$root\modules-$Base\$Arch"){"\$Arch"}else{""};$mods=if($candidate -and !$SameSet){"$root\modules-$Set$sub"}else{"$root\modules-$Base$sub"}
 & $runner "$a\native-game-tiled-assets" "$dir\flags.txt" "$r\live-menu-before.f16" "$dir\rgb" $frames $temporal $mods 0 $(if($frames -eq 12){0}else{1}) 0 0 > "$dir\run.log"
 if($LASTEXITCODE){throw "Replay failed $tag"};Idle
 $rows=@(Import-Csv "$dir\rgb.csv");if($rows.Count -ne $frames -or @($rows|Where-Object{$_.checked -eq '1' -and [int]$_.invalid -ne 0}).Count){throw 'Invalid frames'}
 $mean=($rows|Where-Object{[int]$_.frame -ge $(if($frames -eq 12){1}elseif($frames -ge 1000){200}else{32})}|Measure-Object wall_ms -Average).Average
 [pscustomobject]@{tag=$tag;mean_ms=$mean;sha=(Get-FileHash "$dir\rgb.f16").Hash}|ConvertTo-Json -Compress
}
function Same($b,$t){$files=@(Get-ChildItem "$d\$b" -Filter '*frame-*.f16');if($files.Count -ne 12){throw 'Missing RGB frames'};foreach($f in $files){if((Get-FileHash $f.FullName).Hash -ne (Get-FileHash "$d\$t\$($f.Name)").Hash){throw "Output changed $t"}};"SAME $b $t"}
if(!$TimingOnly){
 foreach($case in @(@{n='900-static';h=900;s=0;t=0},@{n='900-motion';h=900;s=1;t=0},@{n='1080-static';h=1080;s=0;t=0},@{n='1080-motion';h=1080;s=1;t=0},@{n='720-motion';h=720;s=1;t=0},@{n='900-history';h=900;s=5;t=1},@{n='1080-history';h=1080;s=5;t=1})){
  if($Only.Count -and $case.n -notin $Only){continue}
  foreach($c in $false,$true){One "$($case.n)-$c" $case.h $case.s $c 12 $case.t}
  Same "$($case.n)-False" "$($case.n)-True"
 }
}
if(!$CorrectnessOnly){foreach($h in $Heights){foreach($slot in 0..3){One "time-$h-$slot" $h $TimingSequence ($slot -in 1,2) $TimingFrames}}}

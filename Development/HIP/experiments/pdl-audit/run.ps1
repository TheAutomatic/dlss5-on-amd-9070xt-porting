param([switch]$TimingOnly,[int]$Frames=1000,[int]$Rounds=2,[switch]$Rollover)
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\pdl-audit-20260927'
$r='D:\DLSSNR-Lab\hip-backend'
$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
$runner=if($Rollover){"$root\benchmark-rollover.exe"}else{"$root\benchmark.exe"}
$modules='D:\DLSSNR-Lab\re9-runtime-flags-20260926\new\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201'
function One($name,$h,$seq,$temporal,$pdl,$n){
 if(Get-Process SB-Win64-Shipping,LOP-Win64-Shipping,OnimushaWotS,re9 -ErrorAction SilentlyContinue){throw 'Game running'}
 $dir="$root\$name";New-Item -ItemType Directory -Force $dir|Out-Null
 $flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$h",'DLSS5_VIT_ADAPTIVE=0',"DLSS5_RESIDUAL_SEQUENCE=$seq","DLSS5_RESIDUAL_RGB=$(if($n -eq 12){1}else{0})",'DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1',"DLSS5_HIP_PDL=$pdl")
 [IO.File]::WriteAllLines("$dir\flags.txt",$flags)
 & $runner "$a\native-game-tiled-assets" "$dir\flags.txt" "$r\live-menu-before.f16" "$dir\rgb" $n $temporal $modules 0 $(if($n -eq 12){0}else{1}) 0 0 > "$dir\run.log"
 if($LASTEXITCODE){throw "Replay failed $name"}
 $rows=@(Import-Csv "$dir\rgb.csv")
 if($rows.Count -ne $n -or @($rows|Where-Object{$_.checked -eq '1' -and [int]$_.invalid -ne 0}).Count){throw "Invalid output $name"}
 $mean=($rows|Where-Object{[int]$_.frame -ge $(if($n -eq 12){1}else{200})}|Measure-Object wall_ms -Average).Average
 "$name,$h,$pdl,$mean,$((Get-FileHash "$dir\rgb.f16").Hash)"|Add-Content "$root\results.csv"
}
if(!(Test-Path "$root\results.csv")){'name,height,pdl,mean_ms,sha256'|Set-Content "$root\results.csv"}
if($Rollover){
 foreach($h in 900,1080){
  One "rollover-$h" $h 5 1 1 12
  $ref="$root\$h-5-1-1";$test="$root\rollover-$h"
  $files=@(Get-ChildItem $ref -Filter '*frame-*.f16');if($files.Count -ne 12){throw 'Missing reference'}
  foreach($f in $files){if((Get-FileHash $f.FullName).Hash -ne (Get-FileHash "$test\$($f.Name)").Hash){throw 'Rollover changed output'}}
  $resets=@(Select-String "$test\run.log" -Pattern 'PDL_ROLLOVER').Count
  if($resets -lt 1){throw 'Rollover path did not execute'}
  "ROLLOVER_SAME $h 12 frames resets=$resets"|Add-Content "$root\correctness.txt"
 }
}elseif(!$TimingOnly){
 foreach($case in @(@(720,1,0),@(900,0,0),@(900,1,0),@(1080,0,0),@(1080,1,0),@(900,5,1),@(1080,5,1))){
  $h=$case[0];$s=$case[1];$t=$case[2];$tag="$h-$s-$t"
  foreach($p in 1,0){One "$tag-$p" $h $s $t $p 12}
  $files=@(Get-ChildItem "$root\$tag-1" -Filter '*frame-*.f16');if($files.Count -ne 12){throw 'Missing frames'}
  foreach($f in $files){if((Get-FileHash $f.FullName).Hash -ne (Get-FileHash "$root\$tag-0\$($f.Name)").Hash){throw "Mismatch $tag $($f.Name)"}}
  "SAME $tag 12 frames"|Add-Content "$root\correctness.txt"
 }
}else{
 foreach($h in 900,1080){foreach($round in 1..$Rounds){$slot=0;foreach($p in 1,0,0,1){One "time-$h-$round-$slot" $h 0 0 $p $Frames;$slot++}}}
}
'PDL_AUDIT_DONE'

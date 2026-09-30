param([string]$Filter='runtime-regression-A-k*')
$root='D:\DLSSNR-Lab\hip-backend\c512-xblock-queue-20261001'
function P99($v){$s=@($v|Sort-Object);$s[[math]::Ceiling(0.99*$s.Count)-1]}
foreach($d in Get-ChildItem $root -Directory -Filter $Filter){foreach($h in 900,1080){if(!(Test-Path "$($d.FullName)\time-$h-0\rgb.csv")){continue}
 $b=@();$c=@();foreach($slot in 0..3){$rows=@(Import-Csv "$($d.FullName)\time-$h-$slot\rgb.csv"|Where-Object{[int]$_.frame -ge 200}|ForEach-Object{[double]$_.wall_ms});if($slot -in 1,2){$c+=$rows}else{$b+=$rows}}
 $bm=($b|Measure-Object -Average).Average;$cm=($c|Measure-Object -Average).Average
 "{0} {1}: avg {2:N4} -> {3:N4} ({4:+0.0000;-0.0000} ms)  p99 {5:N4} -> {6:N4}" -f $d.Name,$h,$bm,$cm,($cm-$bm),(P99 $b),(P99 $c)}}

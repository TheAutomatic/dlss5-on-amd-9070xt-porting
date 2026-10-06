if(Get-Process | ? {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^Magpie'}){'GPU BUSY';exit}
Set-Location D:\DLSSNR-Lab\competitor-timing-20260930\mz
$cfg=@(@('1920x1080',1920,1080),@('1600x900',1600,900),@('3840x2160',3840,2160))
foreach($r in 1..3){ foreach($c in $cfg){
  if($c[0] -eq '3840x2160' -and $r -gt 1){continue}
  $o=.\nr_graph.exe --plan "plan-$($c[0]).txt" --model-pack dlssnr.bin --spv-dir spv --host-boundary --reuse --source-width $c[1] --source-height $c[2] --accumulation fp32 --pipeline-cache pc.bin --warmup 50 --repeats 500 2>&1
  $o | out-file -encoding ascii "run$r-$($c[0]).log"
  "$r $($c[0]) " + (($o | sls 'one submit|working extent|GPU total') -join ' | ')
}}

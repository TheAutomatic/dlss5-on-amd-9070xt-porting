if(Get-Process | ? {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^Magpie'}){'GPU BUSY';exit}
Set-Location D:\DLSSNR-Lab\competitor-timing-20260930\mz
New-Item -ItemType Directory -Force D:\DLSSNR-Lab\mochizuki-gap-20261001 | out-null
foreach($c in @(@('1600x900',1600,900),@('1920x1080',1920,1080))){
 foreach($r in 1..2){
  $o=.\nr_graph.exe --plan "plan-$($c[0]).txt" --model-pack dlssnr.bin --spv-dir spv --host-boundary --reuse --source-width $c[1] --source-height $c[2] --accumulation fp32 --pipeline-cache pc.bin --warmup 50 --repeats 200 --per-layer --dispatch-grid 2>&1
  $o | out-file -encoding ascii "D:\DLSSNR-Lab\mochizuki-gap-20261001\pl$r-$($c[0]).log"
  "$r $($c[0]) " + (($o | sls 'one submit|sum of the') -join ' | ')
 }}

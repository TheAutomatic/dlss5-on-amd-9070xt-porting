if(Get-Process | ? {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^Magpie'}){'GPU BUSY';exit}
Set-Location D:\DLSSNR-Lab\competitor-timing-20260930\mz
.\nr_graph.exe --plan plan-1920x1080.txt --model-pack dlssnr.bin --spv-dir spv --host-boundary --reuse --source-width 1920 --source-height 1080 --accumulation fp32 --warmup 20 --repeats 100 2>&1 | select -last 40

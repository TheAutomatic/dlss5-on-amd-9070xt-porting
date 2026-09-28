$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\deep-layers'
foreach($shape in @(@(60,36),@(52,32))){
 if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^runtime-smoke|^rtc_compile|^microbench'}){throw 'GPU busy'}
 & "$r\microbench.exe" "$r\daniel-gfx1201.hsaco" $shape[0] $shape[1] 200 3 "$r\flat-A" *> "$r\micro-$($shape[0])x$($shape[1]).log"
 if($LASTEXITCODE){throw 'microbench failed'}
}
'MICRO_DONE (synthetic data only)'

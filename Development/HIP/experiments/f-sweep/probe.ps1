# f-sweep GPU probes on gfx1201 with the module compiler; hosts reused from c512-av-f (probe_z.exe / probe_r.exe).
$ErrorActionPreference='Continue';$root='D:\DLSSNR-Lab\hip-backend\f-sweep-20260930';$av='D:\DLSSNR-Lab\hip-backend\c512-av-f-20260930'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^Magpie'}){throw 'GPU busy'}
foreach($p in 'probe_a','probe_b'){& 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' "$root\$p.hsaco" "$root\$p.hip" comgr gfx1201|Out-Null;if($LASTEXITCODE){throw 'compile'}
 & "$av\probe_z.exe" "$root\$p.hsaco" 2>$null|Tee-Object "$root\$p.log";"$p EXIT $LASTEXITCODE"}
& 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' "$root\probe_r2.hsaco" "$root\probe_r2.hip" comgr gfx1201|Out-Null
& "$av\probe_r.exe" "$root\probe_r2.hsaco" 2>&1|Tee-Object "$root\probe_r2.log";"r2 EXIT $LASTEXITCODE"

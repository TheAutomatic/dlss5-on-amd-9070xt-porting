# GPU exhaustive run of F(Hrtz(x)) vs F(mask(x)) over all 2^32 patterns (probe_f.hip compiled like the modules, gfx1201).
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\composite-quant-c512-20260930'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^Magpie'}){throw 'GPU busy'}
& 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' "$root\probe_f.hsaco" "$root\probe_f.hip" comgr gfx1201|Out-Null;if($LASTEXITCODE){throw 'probe compile'}
& "$root\probe_f.exe" "$root\probe_f.hsaco" 2>$null|Tee-Object "$root\probe.log"
"PROBE_EXIT $LASTEXITCODE"

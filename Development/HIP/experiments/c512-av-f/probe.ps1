# GPU exhaustive run of probe_z.hip (compiled like the modules, gfx1201) over all 2^32 patterns.
$ErrorActionPreference='Continue';$root='D:\DLSSNR-Lab\hip-backend\c512-av-f-20260930'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^Magpie'}){throw 'GPU busy'}
& 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' "$root\probe_z.hsaco" "$root\probe_z.hip" comgr gfx1201|Out-Null;if($LASTEXITCODE){throw 'probe compile'}
& "$root\probe_z.exe" "$root\probe_z.hsaco" 2>&1|Tee-Object "$root\probe.log"
"PROBE_EXIT $LASTEXITCODE"

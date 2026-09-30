# WMMA P.V chain sign-of-zero probe (probe_w.hip, gfx1201, module compiler).
$ErrorActionPreference='Continue';$root='D:\DLSSNR-Lab\hip-backend\c512-av-f-20260930'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^Magpie'}){throw 'GPU busy'}
& 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' "$root\probe_w.hsaco" "$root\probe_w.hip" comgr gfx1201|Out-Null;if($LASTEXITCODE){throw 'probe compile'}
& "$root\probe_w.exe" "$root\probe_w.hsaco" 2>&1|Tee-Object "$root\probe-w.log"
"PROBE_EXIT $LASTEXITCODE"

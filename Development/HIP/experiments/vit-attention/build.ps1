$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\vit-attention-20260929'
foreach($arch in 'gfx1200','gfx1201'){
 if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^rtc_compile|^Magpie'}){throw 'GPU busy'}
 New-Item -ItemType Directory -Force "$root\probe\$arch"|Out-Null
 & 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' "$root\probe\$arch\probe.hsaco" "$root\probe.hip" comgr $arch
 if($LASTEXITCODE){throw 'Compile failed'}
}
Compress-Archive "$root\probe\*" "$root\probe.zip" -Force

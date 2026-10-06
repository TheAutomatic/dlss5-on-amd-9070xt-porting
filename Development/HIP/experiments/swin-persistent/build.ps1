$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929'
foreach($arch in 'gfx1200','gfx1201'){
 if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^rtc_compile'}){throw 'GPU lab busy'}
 New-Item -ItemType Directory -Force "$root\candidate\$arch"|Out-Null
 & 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' "$root\candidate\$arch\swin-persistent.hsaco" "$root\swin-persistent.hip" comgr $arch
 if($LASTEXITCODE){throw "Compile failed $arch"}
}

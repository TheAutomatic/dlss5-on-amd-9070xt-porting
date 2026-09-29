$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929'
Expand-Archive "$root\production-source.zip" "$root\production-source" -Force
foreach($arch in 'gfx1200','gfx1201'){
 foreach($module in 'swin-persistent','c64-wave2'){
  if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^rtc_compile'}){throw 'GPU lab busy'}
  & "$root\production-source\build-modules.ps1" -SourceDir "$root\production-source" -OutputDir "$root\production\$arch" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets $arch -Only $module
  if(!$?){throw 'Production compile failed'}
 }
}
Compress-Archive "$root\production\*" "$root\production.zip" -Force

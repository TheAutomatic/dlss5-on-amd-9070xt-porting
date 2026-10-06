$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\kernel-map'
foreach($arch in 'gfx1200','gfx1201'){
 foreach($module in 'deep_fast-packed','multihead-fast-padded-wave-packed'){
  if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^recorder|^jobbench|^microbench|^rtc_compile'}){throw 'GPU busy'}
  & "$r\hip-production\build-modules.ps1" -SourceDir "$r\hip-production" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\production\$arch" -Only $module -Targets $arch
  if($LASTEXITCODE){throw 'production compile'}
  $def=if($module -eq 'deep_fast-packed'){'HIP_VIT_ATTN_TRANSPOSED_SCORE 0'}else{'C512_HEAD_GROUP 0'}
  & "$r\hip-production\build-modules.ps1" -SourceDir "$r\hip-production" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\default-off\$arch" -Only $module -Targets $arch -ExtraDefines @($def)
  if($LASTEXITCODE){throw 'default-off compile'}
 }
}
New-Item -ItemType Directory -Force "$r\flat-F"|Out-Null
Copy-Item "$r\flat-A\*.hsaco" "$r\flat-F" -Force
Copy-Item "$r\production\gfx1201\*.hsaco" "$r\flat-F" -Force

$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\vit-attention-20260929'
Expand-Archive "$root\production-source.zip" "$root\production-source" -Force
foreach($arch in 'gfx1200','gfx1201'){foreach($enabled in 0,1){
 if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^rtc_compile|^Magpie'}){throw 'GPU busy'}
 & "$root\production-source\build-modules.ps1" -SourceDir "$root\production-source" -OutputDir "$root\production-$enabled\$arch" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets $arch -Only deep_fast-packed -ExtraDefines @("HIP_VIT_ATTN_NATIVE_HALF $enabled","HIP_VIT_ATTN_PROB_PAIR $enabled","HIP_VIT_ATTN_TRANSPOSED_AV $enabled")
 if(!$?){throw 'Production compile failed'}
}}
Copy-Item "$root\production-1\gfx1201\deep_fast-packed.hsaco" "$root\flat-P\deep_fast-packed.hsaco" -Force
Compress-Archive -Path "$root\production-0","$root\production-1" -DestinationPath "$root\production.zip" -Force

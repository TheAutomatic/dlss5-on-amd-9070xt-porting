param([string]$Arch='gfx1201',[string[]]$Sets=@('Z','L','B','F','BL'))
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c256-fusion'
foreach($set in $Sets){
 if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile'}){throw 'GPU busy'}
 $defs=switch($set){'Z'{@('W2_FFN_QT_BATCH 0','W2_C256_Q_LDS 0')};'L'{@('W2_FFN_QT_BATCH 0','W2_C256_Q_LDS 1')};'B'{@('W2_FFN_QT_BATCH 2','W2_C256_Q_LDS 0')};'F'{@('W2_FFN_QT_BATCH 4','W2_C256_Q_LDS 0')};'F1'{@('W2_FFN_QT_BATCH 4','W2_C256_HIDDEN_TILES 1','W2_C256_Q_LDS 0')};'FL'{@('W2_FFN_QT_BATCH 4','W2_C256_HIDDEN_TILES 1','W2_C256_Q_LDS 1')};'BL'{@('W2_FFN_QT_BATCH 2','W2_C256_Q_LDS 1')};default{throw 'set'}}
 & "$r\hip-test\build-modules.ps1" -SourceDir "$r\hip-test" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-$set-$Arch" -Only c64-wave2 -Targets $Arch -ExtraDefines $defs
 if($LASTEXITCODE){throw 'compile'}
 if($Arch -eq 'gfx1201'){
 New-Item -ItemType Directory -Force "$r\flat-$set"|Out-Null
 Copy-Item "$r\flat-A\*.hsaco" "$r\flat-$set" -Force
 Copy-Item "$r\build-$set-$Arch\c64-wave2.hsaco" "$r\flat-$set\c64-wave2.hsaco" -Force
 }
}

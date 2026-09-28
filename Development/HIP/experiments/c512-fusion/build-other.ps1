param([string]$Arch='gfx1201',[string[]]$Sets=@('D','M','MD','S64','S128','Sboth','W'))
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c512-fusion'
foreach($set in $Sets){
 if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile'}){throw 'GPU busy'}
 $module='deep_fast-packed'
 $defs=switch($set){
 'D'{@('C512_T8_SKIP_FLOAT_OUT 1')}
 'M'{@('C512_T8_M32 1')}
 'MD'{@('C512_T8_M32 1','C512_T8_SKIP_FLOAT_OUT 1')}
 'W'{$module='c64-wave2';@('W2_C256_WAVE16 1')}
 'S64'{$module='c64-wave2';@('W2_FFN_QT_SMALL_MASK 1')}
 'S128'{$module='c64-wave2';@('W2_FFN_QT_SMALL_MASK 2')}
 'Sboth'{$module='c64-wave2';@('W2_FFN_QT_SMALL_MASK 3')}
 default{throw 'set'}
 }
 & "$r\hip-test\build-modules.ps1" -SourceDir "$r\hip-test" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\build-$set-$Arch" -Only $module -Targets $Arch -ExtraDefines $defs
 if($LASTEXITCODE){throw 'compile'}
 if($Arch -eq 'gfx1201'){
 New-Item -ItemType Directory -Force "$r\flat-$set"|Out-Null
 Copy-Item "$r\flat-A\*.hsaco" "$r\flat-$set" -Force
 Copy-Item "$r\build-$set-$Arch\$module.hsaco" "$r\flat-$set\$module.hsaco" -Force
 }
}

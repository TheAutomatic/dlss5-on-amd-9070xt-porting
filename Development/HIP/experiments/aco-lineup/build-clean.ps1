$ErrorActionPreference='Stop'
$r='D:\DLSSNR-Lab\hip-backend\aco-lineup'
if(Get-Process | Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark$'}){throw 'GPU busy'}
foreach($set in 'Z','P'){foreach($m in 'c32-wave1','c64-wave2'){
 $d=@();if($set -eq 'Z'){$d=if($m -eq 'c32-wave1'){@('CW_ACT_FMED3 0')}else{@('W2_BOUNDED_RCP 0')}}
 & "$r\clean-hip\build-modules.ps1" -SourceDir "$r\clean-hip" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\clean-$set-$m" -Only $m -ExtraDefines $d
 if($LASTEXITCODE){throw 'compile'}
}}

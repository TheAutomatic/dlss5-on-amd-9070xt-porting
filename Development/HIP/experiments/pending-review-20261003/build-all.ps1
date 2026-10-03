# pending-review-20261003 module builds (COMGR, offline). Verify recipe-rebuild parity, then candidate macros.
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\pending-review-20261003'
$rtc='D:\DLSSNR-Lab\build-0927\rtc_compile.exe'
if(!(Test-Path $rtc)){throw 'rtc_compile missing'}
function B($name,$module,$defs){
 $D=@($defs -split ','|?{$_}|%{$_ -replace '=',' '})
 & "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-$name\gfx1201" -Compiler $rtc -Targets gfx1201 -Only $module -ExtraDefines $D | Out-Null
 "$name $module $((Get-FileHash "$root\build-$name\gfx1201\$module.hsaco").Hash.Substring(0,8))"
}
B 'RECIPE-dfp' 'deep_fast-packed' ''
B 'RECIPE-mh'  'c512-m32-mh' ''
B 'F8W' 'deep_fast-packed' 'HIP_DEC_F8W 1'
B 'VT'  'c512-m32-mh' 'C512_COMPACT_VT 1'
$installed="$root\flat-A"
foreach($m in 'deep_fast-packed','c512-m32-mh'){
 $i=(Get-FileHash "$installed\$m.hsaco").Hash.Substring(0,8)
 $r=(Get-FileHash "$root\build-RECIPE-$(if($m -eq 'deep_fast-packed'){'dfp'}else{'mh'})\gfx1201\$m.hsaco").Hash.Substring(0,8)
 "PARITY $m installed=$i recipe=$r $(if($i -eq $r){'IDENTICAL'}else{'DIFFERS'})"
}
'BUILDS_DONE'

$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\c512-ffn-lds-20260930'
if(Get-Process|?{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rtc_compile|^jobbench|^Magpie'}){throw 'GPU busy'}
if(Test-Path "$root\src"){Remove-Item "$root\src" -Recurse -Force}
Expand-Archive "$root\src.zip" "$root\src" -Force
$V=[ordered]@{g0=@("C512_MIX_LDS_G 0");u4=@("C512_MIX_LDS_G 4","C512_MIX_LDS_U 4");u2=@("C512_MIX_LDS_G 4","C512_MIX_LDS_U 2");u1=@("C512_MIX_LDS_G 4","C512_MIX_LDS_U 1");g2u2=@("C512_MIX_LDS_G 2","C512_MIX_LDS_U 2");g2u1=@("C512_MIX_LDS_G 2","C512_MIX_LDS_U 1")}
foreach($g in $V.Keys){
 & "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-$g\gfx1201" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets gfx1201 -Only c512-m32-deep -ExtraDefines $V[$g] *> "$root\build-$g.log"
 $f=Get-ChildItem "$root\build-$g" -Recurse -Filter 'c512-m32-deep.hsaco'|Select-Object -First 1
 "$g $((Get-FileHash $f.FullName).Hash) $($f.FullName)"
}

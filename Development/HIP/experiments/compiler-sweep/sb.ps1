# compiler-sweep build: one module, one option set. -Opts goes to RTC_EXTRA_OPTS (joined -mllvm=X form), -Wpe sets HIP_KERNEL_WPE.
param([string]$Name,[string]$Module,[string]$Opts='',[int]$Wpe=0,[string]$Defs='',[switch]$Both)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\compiler-sweep-20261001'
$D=@($Defs -split ','|?{$_}|%{$_ -replace '=',' '});if($Wpe){$D+="HIP_KERNEL_WPE $Wpe"}
$arches=if($Both){'gfx1200','gfx1201'}else{'gfx1201'}
foreach($arch in $arches){& "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-$Name\$arch" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets $arch -Only $Module -ExtraDefines $D -ExtraOpts $Opts -RowOpts|Out-Null
 "$arch $Name $((Get-FileHash "$root\build-$Name\$arch\$Module.hsaco").Hash)"}

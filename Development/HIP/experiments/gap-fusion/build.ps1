# Build one module (gfx1201 only unless -Both) with extra defines into $root\build-<Name>. -Name X -Module m -Defs 'A 1','B 2'
param([string]$Name,[string]$Module,[string[]]$Defs=@(),[switch]$Both)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\gap-fusion-20260930'
$Defs=@($Defs|ForEach-Object{$_ -split ","}|Where-Object{$_}|ForEach-Object{$_ -replace "=", " "})
if(Test-Path "$root\src.zip"){Remove-Item "$root\src" -Recurse -Force -EA 0;Expand-Archive "$root\src.zip" "$root\src" -Force;Remove-Item "$root\src.zip"}
$arches=if($Both){'gfx1200','gfx1201'}else{'gfx1201'}
foreach($arch in $arches){
 & "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-$Name\$arch" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets $arch -Only $Module -ExtraDefines $Defs|Out-Null
 $f=Get-ChildItem "$root\build-$Name\$arch" -Recurse -Filter "$Module.hsaco"|Select-Object -First 1
 $inst=if($arch -eq 'gfx1201'){(Get-FileHash "$root\flat-A\$Module.hsaco").Hash}else{'-'}
 "$arch $Name $Module $((Get-FileHash $f.FullName).Hash) installed $inst"
 if($arch -eq 'gfx1201'){New-Item -ItemType Directory -Force "$root\cand-$Name"|Out-Null;Copy-Item $f.FullName "$root\cand-$Name\$Module.hsaco" -Force}}
'BUILD_DONE'

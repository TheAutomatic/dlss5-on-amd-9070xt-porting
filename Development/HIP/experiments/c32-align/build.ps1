# Build c32-wave1 variants (recipe + extra defines) for both arches; flat-<v> = flat-A with the variant's gfx1201 c32-wave1.
param([string[]]$Only=@())
$ErrorActionPreference='Stop'
$Only=@($Only|ForEach-Object{$_ -split ","}|Where-Object{$_})
$root='D:\DLSSNR-Lab\hip-backend\c32-align-20260930'
if(Test-Path "$root\src"){Remove-Item "$root\src" -Recurse -Force}
Expand-Archive "$root\src.zip" "$root\src" -Force
$variants=[ordered]@{prod=@('CW_DIAG_ONLY 0');S=@('CW_SKIP_BYTE 1');D=@('CW_DIAG_ONLY 1');SD=@('CW_SKIP_BYTE 1','CW_DIAG_ONLY 1')}
foreach($v in $variants.Keys){if($Only.Count -and $Only -notcontains $v){continue}
 foreach($arch in 'gfx1200','gfx1201'){
  if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^jobbench|^Magpie'}){throw 'GPU busy'}
  & "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-$v\$arch" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets $arch -Only c32-wave1 -ExtraDefines $variants[$v]
  if(!$?){throw 'compile failed'}
  $f=Get-ChildItem "$root\build-$v\$arch" -Recurse -Filter 'c32-wave1.hsaco'|Select-Object -First 1
  "$arch $v $((Get-FileHash $f.FullName).Hash) installed $((Get-FileHash "$root\baseline\$arch\c32-wave1.hsaco").Hash)"
  if($arch -eq 'gfx1201'){New-Item -ItemType Directory -Force "$root\flat-$v"|Out-Null;Copy-Item "$root\flat-A\*.hsaco" "$root\flat-$v" -Force;Copy-Item $f.FullName "$root\flat-$v\c32-wave1.hsaco" -Force}
 }}
# multihead-fast-padded-wave-packed (mh_fast) with the byte pool projection export
foreach($arch in 'gfx1200','gfx1201'){if($Only.Count -and $Only -notcontains 'mhB'){break}
 & "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-mhB\$arch" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets $arch -Only multihead-fast-padded-wave-packed -ExtraDefines @('HIP_POOL32_B8 1')
 if(!$?){throw 'compile failed'}
 $f=Get-ChildItem "$root\build-mhB\$arch" -Recurse -Filter 'multihead-fast-padded-wave-packed.hsaco'|Select-Object -First 1
 "$arch mhB $((Get-FileHash $f.FullName).Hash) installed $((Get-FileHash "$root\baseline\$arch\multihead-fast-padded-wave-packed.hsaco").Hash)"}
foreach($set in @{n='B';c='S'},@{n='BD';c='SD'}){if($Only.Count -and $Only -notcontains 'mhB'){break}
 New-Item -ItemType Directory -Force "$root\flat-$($set.n)"|Out-Null;Copy-Item "$root\flat-A\*.hsaco" "$root\flat-$($set.n)" -Force
 Copy-Item "$root\flat-$($set.c)\c32-wave1.hsaco" "$root\flat-$($set.n)" -Force
 Copy-Item (Get-ChildItem "$root\build-mhB\gfx1201" -Recurse -Filter 'multihead-fast-padded-wave-packed.hsaco'|Select-Object -First 1).FullName "$root\flat-$($set.n)" -Force}
'BUILD_DONE'

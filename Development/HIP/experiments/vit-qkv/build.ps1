param([string[]]$Archs=@("gfx1201"),[string[]]$Only=@())
$ErrorActionPreference='Stop'
$Only=@($Only|ForEach-Object{$_ -split ","}|Where-Object{$_})
$root='D:\DLSSNR-Lab\hip-backend\vit-qkv-20260929'
if(Test-Path "$root\src"){Remove-Item "$root\src" -Recurse -Force}
Expand-Archive "$root\src.zip" "$root\src" -Force
$variants=[ordered]@{off=@();hoist=@('HIP_VIT_STREAM_QKV_HOIST 1');w5=@('HIP_VIT_QKV_W5 1');o1=@('HIP_VIT_QKV_ORDER 1');o2=@('HIP_VIT_QKV_ORDER 2');o3=@('HIP_VIT_QKV_ORDER 3')}
foreach($arch in $Archs){foreach($v in $variants.Keys){if($Only.Count -and $Only -notcontains $v){continue}
 if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rtc_compile|^jobbench|^Magpie'}){throw 'GPU busy'}
 $d=$variants[$v];if(!$d.Count){$d=@('HIP_VIT_QKV_W5 0')}
 & "$root\src\build-modules.ps1" -SourceDir "$root\src" -OutputDir "$root\build-$v\$arch" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -Targets $arch -Only vit-stream -ExtraDefines $d
 if(!$?){throw 'compile failed'}
 $f=Get-ChildItem "$root\build-$v\$arch" -Recurse -Filter 'vit-stream.hsaco'|Select-Object -First 1
 "$arch $v $((Get-FileHash $f.FullName).Hash)"
}
"$arch installed $((Get-FileHash "$root\baseline\$arch\vit-stream.hsaco").Hash)"}

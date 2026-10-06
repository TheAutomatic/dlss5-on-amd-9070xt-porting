param([string]$Arch='gfx1201')
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\float-fma'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark$'}){throw 'GPU busy'}
$modules=@('c32_fast','c32_fused_ffn_attention','c32_fused_ffn_attention-packed','c32-wave1','multihead-fast','multihead-fast-packed','multihead-fast-padded-wave','multihead-fast-padded-wave-packed','c64-wave2','c512-m32-mh','deep_fast','deep_fast-packed','c512-m32-deep','vit-stream','vit-wide-deep')
$d="$r\build-$Arch";New-Item -ItemType Directory -Force $d | Out-Null
foreach($m in $modules){
 & "$r\hip-prod\build-modules.ps1" -SourceDir "$r\hip-prod" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir $d -Only $m -Targets $Arch
 if($LASTEXITCODE){throw "compile $m"}
}
$base=if($Arch -eq 'gfx1201'){"$r\flat-A"}else{"$r\baseline-gfx1200"}
$dst=if($Arch -eq 'gfx1201'){"$r\flat-P"}else{"$r\production-gfx1200"}
New-Item -ItemType Directory -Force $dst|Out-Null
Copy-Item "$base\*.hsaco" $dst -Force
Copy-Item "$d\*.hsaco" $dst -Force
Get-ChildItem $dst -Filter '*.hsaco'|ForEach-Object{[pscustomobject]@{module=$_.Name;sha=(Get-FileHash $_.FullName).Hash}}|Export-Csv "$r\modules-$Arch.csv" -NoTypeInformation
if(@(Get-ChildItem $dst -Filter '*.hsaco').Count -ne 30){throw 'module count'}

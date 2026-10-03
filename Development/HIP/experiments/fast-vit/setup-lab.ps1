# fast-vit-c512 lab setup (2026-10-03): clone harness scripts from fast-numeric-20261003, stage flats P1/P2/P3/S/PF.
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\fast-vit-20261003'
$src='D:\DLSSNR-Lab\hip-backend\fast-numeric-20261003'
$b='D:\DLSSNR-Lab\hip-backend\fast-vit-20261003-build'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
New-Item -ItemType Directory -Force $root | Out-Null
# scripts
Copy-Item "$src\regression.ps1","$src\psnr.ps1" $root -Force
foreach($f in 'summarize.ps1','p99m.ps1','full.ps1'){(Get-Content "$src\$f" -Raw).Replace('fast-numeric-20261003','fast-vit-20261003')|Set-Content "$root\$f"}
$t=Get-Content "$src\regression.ps1" -Raw
$o='if($different){throw "Output changed $t ($different/12)"};"SAME $b $t"'
if(!$t.Contains($o)){throw 'same line missing'}
Set-Content "$root\regression-cmp.ps1" ($t.Replace($o,'"CMP $b $t diff=$different/12"').Replace('$root=Split-Path -Parent $MyInvocation.MyCommand.Path','$root=''D:\DLSSNR-Lab\hip-backend\fast-vit-20261003'''))
if((Get-Content "$root\regression.ps1" -Raw) -notmatch 'ADAPTIVE_IDLE_MS=1000000000'){throw 'idle pin missing'}
# hosts
Copy-Item "$src\benchmark-base.exe" $root -Force
Copy-Item "$root\benchmark-F2.exe" "$root\benchmark-F2roll.exe" -Force
# flats
foreach($n in 'A','S','P1','P2','P3'){Remove-Item "$root\flat-$n" -Recurse -Force -EA 0;Copy-Item "$src\flat-A" "$root\flat-$n" -Recurse}
Copy-Item "$b\c1\deep_fast-packed.hsaco" "$root\flat-P1\deep_fast-packed.hsaco" -Force
Copy-Item "$b\c2\vit-stream.hsaco" "$root\flat-P2\vit-stream.hsaco" -Force
Copy-Item "$b\c3\deep_fast-packed.hsaco" "$root\flat-P3\deep_fast-packed.hsaco" -Force
Copy-Item "$b\c3\multihead-fast-padded-wave-packed.hsaco" "$root\flat-P3\multihead-fast-padded-wave-packed.hsaco" -Force
# PF = full fast default: flat-F (c32/c64 fast twins) + the three new -fast twins alongside
Remove-Item "$root\flat-PF" -Recurse -Force -EA 0
Copy-Item "$src\flat-F" "$root\flat-PF" -Recurse
foreach($m in 'deep_fast-packed-fast','vit-stream-fast','multihead-fast-padded-wave-packed-fast'){Copy-Item "$b\final\$m.hsaco" "$root\flat-PF\$m.hsaco" -Force}
"flatA $(@(gci "$root\flat-A" -Filter *.hsaco).Count) P1 $(@(gci "$root\flat-P1" -Filter *.hsaco).Count) PF $(@(gci "$root\flat-PF" -Filter *.hsaco).Count)"
Get-ChildItem "$root\*.exe"|%{"$($_.Name) $((Get-FileHash $_.FullName).Hash.Substring(0,8))"}
'SETUP_DONE'

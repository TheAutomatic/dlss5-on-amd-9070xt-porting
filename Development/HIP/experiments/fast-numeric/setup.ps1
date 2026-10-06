# fast-numeric (2026-10-03, results/fast-numeric-option-20261003) setup: harness from rtz1080; flat-A = installed Stellar gfx1201 (63);
# flat-F = flat-A + c32-wave1-fast + c64-wave2-fast (LLVM23 prebuilt, CW_FAST_NUM 3 / W2_FAST_NUM 3); flat-X = flat-A + junk -fast files (route).
# benchmark-base = main 64d9cfde host, benchmark-F = branch host (DLSS5_FAST_NUMERIC). regression-cmp.ps1 = regression without the SAME throw (lossy PSNR).
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\fast-numeric-20261003';$s='D:\DLSSNR-Lab\hip-backend\rtz1080-20261003'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1','full.ps1'){(Get-Content "$s\$f" -Raw).Replace('rtz1080-20261003','fast-numeric-20261003')|Set-Content "$root\$f"}
if((Get-Content "$root\regression.ps1" -Raw) -notmatch 'ADAPTIVE_IDLE_MS=1000000000'){throw 'idle pin missing'}
$t=Get-Content "$root\regression.ps1" -Raw;$o='if($different){throw "Output changed $t ($different/12)"};"SAME $b $t"';if(!$t.Contains($o)){throw 'same line'}
Set-Content "$root\regression-cmp.ps1" $t.Replace($o,'"CMP $b $t diff=$different/12"').Replace('$root=Split-Path -Parent $MyInvocation.MyCommand.Path','$root=''D:\DLSSNR-Lab\hip-backend\fast-numeric-20261003''')
if(!(Test-Path "$root\assets-base")){Copy-Item "$s\assets-base" "$root\assets-base" -Recurse}
foreach($n in 'A','F','X'){Remove-Item "$root\flat-$n" -Recurse -Force -EA 0;Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201" "$root\flat-$n" -Recurse}
foreach($m in 'c32-wave1-fast','c64-wave2-fast'){Copy-Item "$root\pre23\gfx1201\$m.hsaco" "$root\flat-F\" -Force;[IO.File]::WriteAllBytes("$root\flat-X\$m.hsaco",[byte[]](1..64))}
Copy-Item "$root\bin\benchmark-base.exe","$root\bin\benchmark-F.exe" $root -Force;Copy-Item "$root\bin\benchmark-F.exe" "$root\benchmark-Froll.exe" -Force
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash.Substring(0,8)) sums $((Get-FileHash "$game\DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS").Hash.Substring(0,8)) flatA $(@(gci "$root\flat-A" -Filter *.hsaco).Count) flatF $(@(gci "$root\flat-F" -Filter *.hsaco).Count)"
foreach($m in 'c32-wave1','c32-wave1-rtz','c64-wave2'){"$m installed $((Get-FileHash "$root\flat-A\$m.hsaco").Hash.Substring(0,8)) rebuilt $((Get-FileHash "$root\pre23\gfx1201\$m.hsaco").Hash.Substring(0,8))"}
Get-ChildItem "$root\*.exe"|%{"$($_.Name) $((Get-FileHash $_.FullName).Hash.Substring(0,8))"}
'SETUP_DONE'

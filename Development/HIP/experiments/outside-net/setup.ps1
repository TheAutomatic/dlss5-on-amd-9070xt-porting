# outside-net (2026-10-02, results/outside-net-20261002) setup: harness, flat modules, assets and templates from net-timing-fix-20261002.
# add-on: base = benchmark-base.exe (main a4c84272 host), Q = benchmark-Q.exe (DLSS5_HIP_POST_SIGNAL_QUERY=1), Qroll = Q copy.
# runtime: rt\runtime-<base|D|DQ> = installed Onimusha modules + fusion-round3 shaders + bin\rt-<side>\LmxxfNrRuntime.dll.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\outside-net-20261002';$s='D:\DLSSNR-Lab\hip-backend\net-timing-fix-20261002'
$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1','full.ps1'){(Get-Content "$s\$f" -Raw).Replace('net-timing-fix-20261002','outside-net-20261002')|Set-Content "$root\$f"}
if((Get-Content "$root\regression.ps1" -Raw) -notmatch 'ADAPTIVE_IDLE_MS=1000000000'){throw 'idle pin missing'}
foreach($n in 'A','Q'){Remove-Item "$root\flat-$n" -Recurse -Force -EA 0;Copy-Item "$oni\$hip\gfx1201" "$root\flat-$n" -Recurse}
Remove-Item "$root\assets-base","$root\templates" -Recurse -Force -EA 0;Copy-Item "$s\assets-base" "$root\assets-base" -Recurse;Copy-Item "$s\templates" "$root\templates" -Recurse
Copy-Item "$root\bin\benchmark-base.exe","$root\bin\benchmark-Q.exe","$root\bin\rt_outside.exe" $root -Force;Copy-Item "$root\bin\benchmark-Q.exe" "$root\benchmark-Qroll.exe" -Force
foreach($side in 'base','D','DQ'){$d="$root\rt\runtime-$side";Remove-Item -Recurse -Force $d -EA 0;New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders"|Out-Null
 foreach($a in 'gfx1200','gfx1201'){Copy-Item "$oni\$hip\$a\*.hsaco" "$d\modules\$a" -Force}
 Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force
 Copy-Item "$root\bin\rt-$side\LmxxfNrRuntime.dll" "$d\LmxxfNrRuntime.dll" -Force
 $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring(("$d\modules\").Length).Replace('\','/'))"});[IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)}
foreach($n in 'A','Q'){"flat$n $(@(gci "$root\flat-$n" -Filter *.hsaco).Count)"}
Get-ChildItem "$root\*.exe","$root\rt\runtime-*\*.dll"|%{"$($_.FullName.Substring($root.Length+1)) $((Get-FileHash $_.FullName).Hash.Substring(0,8))"}
'SETUP_DONE'

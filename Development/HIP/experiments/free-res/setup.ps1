# free-res (2026-10-02) setup: harness from net-timing-20261002 (itself next-candidate's, idle pinned), all sides on the installed modules (flat-N).
# base = benchmark-base.exe (main fe4d1d73 host) + assets-base; F = benchmark-F.exe (free-res host, DLSS5_NETWORK_FREE_RES unset = 0) + assets-cand
# (assets-base + the six changed shaders); Froll = F copy for the rollover pass.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\free-res-20261002';$s='D:\DLSSNR-Lab\hip-backend\net-timing-20261002';$n='D:\DLSSNR-Lab\hip-backend\next-candidate-20261002'
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1','full.ps1'){(Get-Content "$s\$f" -Raw).Replace('net-timing-20261002','free-res-20261002')|Set-Content "$root\$f"}
if((Get-Content "$root\regression.ps1" -Raw) -notmatch 'ADAPTIVE_IDLE_MS=1000000000'){throw 'idle pin missing'}
foreach($x in 'A','F'){Remove-Item "$root\flat-$x" -Recurse -Force -EA 0;New-Item -ItemType Directory "$root\flat-$x"|Out-Null;Copy-Item "$n\flat-N\*.hsaco" "$root\flat-$x"}
foreach($x in 'assets-base','assets-cand'){Remove-Item "$root\$x" -Recurse -Force -EA 0;Copy-Item "$n\assets-base" "$root\$x" -Recurse}
foreach($h in 'native_codec_encode','native_game_rgb_input','native_temporal_coordinates','native_temporal_sample','native_history_guard','native_output_smooth'){Copy-Item "$root\bin\$h.hlsl" "$root\assets-cand\$h.hlsl" -Force}
Copy-Item "$root\bin\benchmark-base.exe","$root\bin\benchmark-F.exe","$root\bin\ngx-base.exe","$root\bin\ngx-F.exe" $root -Force;Copy-Item "$root\bin\benchmark-F.exe" "$root\benchmark-Froll.exe" -Force
foreach($x in 'A','F'){"flat$x $(@(gci "$root\flat-$x" -Filter *.hsaco).Count)"}
Get-ChildItem "$root\*.exe","$root\bin\rt-*\*.dll","$root\assets-cand\native_*.hlsl"|%{"$($_.Name) $((Get-FileHash $_.FullName).Hash.Substring(0,8))"}
'SETUP_DONE'

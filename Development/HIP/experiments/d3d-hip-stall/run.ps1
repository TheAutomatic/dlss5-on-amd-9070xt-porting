$ErrorActionPreference='Stop';$root=$PSScriptRoot
function Idle{& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'};if(Get-Process -EA 0|Where-Object{$_.ProcessName -match '^benchmark|^rt_bench|^speed_probe|^jobbench|^pending-probe'}){throw 'lab busy'}}
Idle
$f=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$b=[Text.Encoding]::UTF8.GetBytes('d3d-hip-stall-20261004');$f.Write($b,0,$b.Length);$f.Close()
$env:STALL_QUERY_END='1'
try{foreach($pace in 0,8){$env:STALL_PACE_MS="$pace";foreach($mib in 64,256,2048){Idle;$name="query-pace-$pace-mib-$mib";$ErrorActionPreference='Continue';& "$root\speed_probe.exe" 1 $mib 40 > "$root\$name.log" 2> "$root\$name.err";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw "probe failed $name"};Get-Content "$root\$name.log" -Tail 1}}
'SPEED_SCAN_DONE'
}finally{if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -eq 'd3d-hip-stall-20261004'){Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}}
